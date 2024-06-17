# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  hashistack_image_project_id = var.hashistack_image_project_id != "" ? var.hashistack_image_project_id : var.project_id
}

resource "null_resource" "packer_build" {
  count      = var.build_hashistack_image ? 1 : 0
  depends_on = [google_project_service.compute]

  triggers = {
    hashistack_image_name = var.hashistack_image_name
    hashistack_image_project_id = local.hashistack_image_project_id
    zone_id = local.zone_id
  }

  provisioner "local-exec" {
    when = create
    command = <<EOF
cd ../../packer && \
  packer init -force gcp-packer.pkr.hcl && \
  packer build -force \
    -var zone=${self.triggers.zone_id} \
    -var project_id=${self.triggers.hashistack_image_project_id} \
    -var image_name=${self.triggers.hashistack_image_name} \
    gcp-packer.pkr.hcl
EOF
  }
}

data "google_compute_image" "hashistack" {
  depends_on = [null_resource.packer_build]
  name       = var.hashistack_image_name
  project    = local.hashistack_image_project_id
}
