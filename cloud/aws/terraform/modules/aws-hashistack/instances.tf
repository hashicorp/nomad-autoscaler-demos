# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

resource "aws_instance" "nomad_server" {
  ami                    = var.ami
  instance_type          = var.server_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.primary.id]
  count                  = var.server_count

  tags = {
    Name           = "${var.stack_name}-server-${count.index + 1}"
    ConsulAutoJoin = "auto-join"
    OwnerName      = var.owner_name
    OwnerEmail     = var.owner_email
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = templatefile(
    "${path.module}/templates/user-data-server.sh", {
      server_count  = var.server_count
      region        = var.region
      retry_join    = var.retry_join
      consul_binary = var.consul_binary
      nomad_binary  = var.nomad_binary
    })

  iam_instance_profile = aws_iam_instance_profile.nomad_server.name
}
