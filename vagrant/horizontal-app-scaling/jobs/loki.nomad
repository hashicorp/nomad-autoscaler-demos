# Copyright IBM Corp. 2020, 2026
# SPDX-License-Identifier: MPL-2.0

job "loki" {
  datacenters = ["dc1"]

  group "loki" {
    count = 1

    network {
      port "loki" {}
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:3.5.5"
        ports = ["loki"]

        args = [
          "--config.file=/etc/loki/config/loki.yml",
        ]

        volumes = [
          "local/config:/etc/loki/config",
        ]
      }

      template {
        data = <<EOH
---
auth_enabled: false
server:
  http_listen_port: {{ env "NOMAD_PORT_loki" }}
common:
  ring:
    kvstore:
      store: inmemory
    instance_addr: 127.0.0.1
  replication_factor: 1
  path_prefix: /loki
ingester:
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  wal:
    dir: /loki/wal
schema_config:
  configs:
  - from: 2024-01-01
    store: tsdb
    object_store: filesystem
    schema: v13
    index:
      prefix: index_
      period: 24h
storage_config:
  tsdb_shipper:
    active_index_directory: /loki/tsdb-index
    cache_location: /loki/tsdb-cache
  filesystem:
    directory: /loki/chunks
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  allow_structured_metadata: false
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/loki.yml"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name     = "loki"
        provider = "nomad"
        port     = "loki"

        check {
          type     = "http"
          path     = "/ready"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
