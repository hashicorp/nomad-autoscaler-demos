# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "google_compute_address" "nomad_server" {
  name = local.server_stack_name
}

resource "google_compute_address" "nomad_client" {
  name = local.client_stack_name
}
