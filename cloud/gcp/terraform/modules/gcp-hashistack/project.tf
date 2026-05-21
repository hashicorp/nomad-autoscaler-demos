# Copyright IBM Corp. 2020, 2026
# SPDX-License-Identifier: MPL-2.0

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}
