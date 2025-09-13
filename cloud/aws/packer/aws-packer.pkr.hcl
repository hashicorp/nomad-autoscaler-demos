# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# https://developer.hashicorp.com/nomad/tutorials/autoscaler/horizontal-cluster-scaling?in=nomad%2Fautoscaler#build-demo-environment-ami
# The "packer build ."" command loads all the contents in the current directory.
# USAGE:  source env-pkr-var.sh && packer init . && packer validate . && packer build .

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "hashistack" {
  temporary_key_pair_type = "ed25519"
  ami_name      = format("%s%s", var.name_prefix, "-{{timestamp}}")
  region        = var.region
  instance_type = "t3a.2xlarge"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/*ubuntu-${var.os_name}-${var.os_version}-amd64-server-*"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"] # Canonical's owner ID
    most_recent = true
  }

  communicator = "ssh"
  ssh_username = "ubuntu"

  tags = {
    Name           = format("%s%s", var.name_prefix, formatdate("'_'YYYY-MM-DD", timestamp()))
    Architecture   = var.architecture
    OS             = var.os
    OS_Version     = var.os_version
    CNI_Version    = var.cni_version
    Consul_Version = var.consul_version
    Nomad_Version  = var.nomad_version
    Vault_Version  = var.vault_version
    Consul_Template_Version = var.consul_template_version
    Created_Email  = var.created_email
    Created_Name   = var.created_name
  }
}

build {
  sources = [
    "source.amazon-ebs.hashistack"
  ]

  provisioner "shell" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  provisioner "shell" {
    valid_exit_codes = [  ## Redefine exit codes.  https://stackoverflow.com/questions/70719041/packer-errors-on-attempt-to-run-a-script
      "0",
      "1",
      "2"
    ]
    inline = [
      "echo set debconf to Noninteractive", 
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections" ]
  }

  provisioner "shell" {
    valid_exit_codes = [  ## Redefine exit codes.  https://stackoverflow.com/questions/70719041/packer-errors-on-attempt-to-run-a-script
      "0",
      "1",
      "2"
    ]
    inline = [
      "sudo fuser -v -k /var/cache/debconf/config.dat"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /ops",
      "sudo chmod 777 /ops"
    ]
  }

  provisioner "file" {
    source      = "../../shared/packer/"
    destination = "/ops"
  }

  provisioner "shell" {
    script = "../../shared/packer/scripts/setup.sh"
    environment_vars = [
      "CNIVERSION=${var.cni_version}",
      "CONSULVERSION=${var.consul_version}",
      "NOMADVERSION=${var.nomad_version}"
    ]
  }
}
