# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data_dir   = "/opt/nomad/data"
bind_addr  = "0.0.0.0"
log_level  = "DEBUG"
datacenter = DATACENTER

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

client {
  enabled    = true
  node_class = NODE_CLASS

  options {
    "driver.raw_exec.enable"    = "1"
    "docker.privileged.enabled" = "true"
  }
}

vault {
  enabled = true
  address = "http://active.vault.service.consul:8200"
}
