# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

resource "aws_instance" "servers" {
  count = var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(var.subnet_ids, count.index)
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.servers.name
  user_data              = templatefile(
    "${path.module}/templates/user-data.sh.tpl", {
      server_count  = var.instance_count
      retry_join    = var.retry_join
      consul_binary = var.consul_binary
      nomad_binary  = var.nomad_binary
    })

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = "true"
  }

  tags = {
    Name           = "${var.stack_name}-server-${count.index + 1}"
    ConsulAutoJoin = "auto-join"
    OwnerName      = var.owner_name
    OwnerEmail     = var.owner_email
  }
}
