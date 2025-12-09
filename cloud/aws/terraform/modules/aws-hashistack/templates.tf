# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

locals {
  rendered_template = templatefile(
    "${path.module}/templates/aws_autoscaler.nomad.tpl", {
      nomad_autoscaler_image = var.nomad_autoscaler_image
      client_asg_name        = aws_autoscaling_group.nomad_client.name
    })
}

resource "null_resource" "nomad_autoscaler_jobspec" {
  provisioner "local-exec" {
    command = "echo '${local.rendered_template}' > aws_autoscaler.nomad"
  }
}
