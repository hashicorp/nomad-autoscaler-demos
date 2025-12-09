# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "clients" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:DescribeInstanceRefreshes",
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "clients" {
  name_prefix        = var.stack_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    OwnerName  = var.owner_name
    OwnerEmail = var.owner_email
  }
}

resource "aws_iam_instance_profile" "clients" {
  name_prefix = var.stack_name
  role        = aws_iam_role.clients.name
}


resource "aws_iam_role_policy" "clients" {
  name_prefix = var.stack_name
  role        = aws_iam_role.clients.id
  policy      = data.aws_iam_policy_document.clients.json
}
