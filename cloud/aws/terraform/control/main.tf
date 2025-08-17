# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = {
      version = "~> 2.65"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "nomad" {
  address = "http://${module.hashistack_cluster.server_elb_dns}:4646"
}

module "my_ip_address" {
  source = "matti/resource/shell"

  command = "curl https://ipinfo.io/ip"
}

module "hashistack_cluster" {
  source = "../modules/aws-hashistack"

  region                = var.region
  availability_zones    = var.availability_zones
  ami                   = var.ami
  key_name              = var.key_name
  owner_name            = var.owner_name
  owner_email           = var.owner_email
  stack_name            = var.stack_name
  allowlist_ip          = ["${module.my_ip_address.stdout}/32"]
  server_instance_type  = var.server_instance_type
  client_instance_type  = var.client_instance_type
}

module "hashistack_jobs" {
  source = "../../../shared/terraform/modules/shared-nomad-jobs"

  nomad_addr = "http://${module.hashistack_cluster.server_elb_dns}:4646"
}
