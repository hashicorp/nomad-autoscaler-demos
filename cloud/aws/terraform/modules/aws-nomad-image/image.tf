# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  build_image = var.ami_id == ""
  image       = local.build_image ? data.aws_ami.built[0] : data.aws_ami.existing[0]
  image_id    = local.image.id
  snapshot_id = [for b in local.image.block_device_mappings : lookup(b.ebs, "snapshot_id", "")][0]
}

resource "null_resource" "packer_build" {
  count = local.build_image ? 1 : 0

  provisioner "local-exec" {
    working_dir = "${path.root}/../../packer"
    command = <<EOF
source env-pkr-var.sh && \
  packer build -force \
    -var 'created_name=${var.owner_name}' \
    -var 'created_email=${var.owner_email}' \
    -var 'region=${var.region}' \
    -var 'name_prefix=${var.stack_name}' \
    .
EOF
  }
}

resource "local_file" "cleanup" {
  count = local.build_image ? 1 : 0

  content         = "${local.image_id},${local.snapshot_id},${var.region}"
  filename        = ".cleanup-${local.image_id}"
  file_permission = "0644"

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
aws ec2 deregister-image --image-id ${split(",", self.content)[0]} --region ${split(",", self.content)[2]} &&
aws ec2 delete-snapshot --snapshot-id ${split(",", self.content)[1]} --region ${split(",", self.content)[2]}
EOF
  }
}

data "aws_ami" "built" {
  depends_on = [null_resource.packer_build]
  count      = local.build_image ? 1 : 0

  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.stack_name}-*"]
  }
}

data "aws_ami" "existing" {
  count = local.build_image ? 0 : 1

  owners      = ["self"]
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}