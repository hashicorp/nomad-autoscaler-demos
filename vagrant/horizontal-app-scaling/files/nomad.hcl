# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

datacenter = "dc1"

data_dir = "/opt/nomad"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true

  host_volume "grafana" {
    path = "/opt/nomad-volumes/grafana"
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}
