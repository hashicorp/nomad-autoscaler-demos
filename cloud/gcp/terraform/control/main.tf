# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Providers
provider "nomad" {
  address = module.hashistack_cluster.nomad_addr
}

provider "google" {
  region  = var.region
  zone    = var.zone
  project = var.project_id
}

# Modules
module "my_ip_address" {
  source  = "matti/resource/shell"
  command = "curl https://ipinfo.io/ip"
}

module "hashistack_cluster" {
  source = "../modules/gcp-hashistack"

  project_id   = var.project_id
  allowlist_ip = ["${module.my_ip_address.stdout}/32"]
}

module "hashistack_jobs" {
  source     = "../../../shared/terraform/modules/shared-nomad-jobs"
  depends_on = [module.hashistack_cluster]
  nomad_addr = module.hashistack_cluster.nomad_addr
}

# GCP Project
resource "random_pet" "hashistack" {}