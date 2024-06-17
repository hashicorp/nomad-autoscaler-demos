# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  nomad_autoscaler_jobspec = templatefile(
              "${path.module}/templates/gcp_autoscaler.nomad.tpl",
              {
                nomad_autoscaler_image = var.nomad_autoscaler_image
                project                = var.project_id
                region                 = var.region
                zone                   = local.zone_id
                mig_type               = var.client_mig_type
                mig_name               = local.client_mig_name
              }
            )
}

resource "null_resource" "nomad_autoscaler_jobspec" {
  provisioner "local-exec" {
    command = "echo '${local.nomad_autoscaler_jobspec}' > gcp_autoscaler.nomad"
  }
}
