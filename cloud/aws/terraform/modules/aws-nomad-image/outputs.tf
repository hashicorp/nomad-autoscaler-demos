# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "id" {
  description = "The ID of the AMI to use for instances."
  value       = local.image_id
}

output "snapshot_id" {
  description = "The ID of the EBS snapshot associated with the AMI."
  value       = local.snapshot_id
}