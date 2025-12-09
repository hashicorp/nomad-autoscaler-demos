# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">= 0.13"
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = ">= 1.4.6"
    }
  }
}
