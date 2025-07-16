# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "owner_name" {}
variable "owner_email" {}
variable "region" {}
variable "availability_zones" {}
variable "ami" {}
variable "key_name" {}

variable "stack_name" {
  default = "hashistack"
}
