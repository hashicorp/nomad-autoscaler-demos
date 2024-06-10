# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">= 0.13"
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = ">= 2.3.0"
    }
  }
}
