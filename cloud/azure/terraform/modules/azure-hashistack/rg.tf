# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

resource "random_pet" "server" {}

resource "azurerm_resource_group" "hashistack" {
  name     = "hashistack-${random_pet.server.id}"
  location = var.location
}
