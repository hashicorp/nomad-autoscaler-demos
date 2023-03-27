# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "servers" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "servers" {
  name_prefix        = "${var.stack_name}-servers"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = {
    OwnerName  = var.owner_name
    OwnerEmail = var.owner_email
  }
}

resource "aws_iam_role_policy" "servers" {
  name_prefix = var.stack_name
  role        = aws_iam_role.servers.id
  policy      = data.aws_iam_policy_document.servers.json
}

resource "aws_iam_instance_profile" "servers" {
  name_prefix = var.stack_name
  role        = aws_iam_role.servers.name
}
