variable "owner_email" {}
variable "owner_name" {}
variable "region" {}
variable "stack_name" {}

source "amazon-ebs" "hashistack" {
  ami_name      = var.stack_name
  region        = var.region
  instance_type = "t2.medium"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"] # Canonical's owner ID
    most_recent = true
  }

  communicator = "ssh"
  ssh_username = "ubuntu"

  tags = {
    OS           = "Ubuntu"
    Release      = "20.04"
    Architecture = "amd64"
    OwnerName    = var.owner_name
    OwnerEmail   = var.owner_email
  }
}

build {
  sources = [
    "source.amazon-ebs.hashistack"
  ]

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
  }
}
