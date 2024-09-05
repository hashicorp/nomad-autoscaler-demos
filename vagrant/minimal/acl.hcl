# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

namespace "default" {
  policy = "scale"
}

operator {
  policy = "read"
}

namespace "default" {
  variables {
    path "nomad-autoscaler/lock" {
      capabilities = ["write"]
    }
  }
}
