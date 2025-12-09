# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

job "prometheus" {
  datacenters = ["platform"]

  group "prometheus" {
    network {
      port "prometheus_ui" {}
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.25.0"
        ports = ["prometheus_ui"]

        args = [
          "--config.file=${NOMAD_TASK_DIR}/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.listen-address=0.0.0.0:${NOMAD_PORT_prometheus_ui}",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
        ]
      }

      template {
        data = <<EOH
---
global:
  scrape_interval:     1s
  evaluation_interval: 1s

scrape_configs:
  - job_name: nomad
    scrape_interval: 10s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
    consul_sd_configs:
    - server: '{{ env "attr.unique.network.ip-address" }}:8500'
      services: ['nomad','nomad-client']
    relabel_configs:
      - source_labels: ['__meta_consul_tags']
        regex: .*,http,.*
        action: keep
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/prometheus.yml"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name = "prometheus"
        port = "prometheus_ui"

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.prometheus.entrypoints=prometheus",
          "traefik.tcp.routers.prometheus.rule=HostSNI(`*`)"
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
