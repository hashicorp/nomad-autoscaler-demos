# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"
log_level = "DEBUG"

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

server {
  enabled          = true
  bootstrap_expect = SERVER_COUNT
}
