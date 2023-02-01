# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "traefik" {
  datacenters = ["platform"]
  type        = "system"

  group "traefik" {
    network {
      port "api" {
        static = 8081
      }

      port "grafana" {
        static = 3000
      }

      port "prometheus" {
        static = 9090
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.2"
        ports = ["api", "grafana", "prometheus"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
  [entryPoints.traefik]
    address = ":{{ env "NOMAD_PORT_api" }}"

  [entryPoints.grafana]
    address = ":{{ env "NOMAD_PORT_grafana" }}"

  [entryPoints.prometheus]
    address = ":{{ env "NOMAD_PORT_prometheus" }}"

[api]
  dashboard = true
  insecure  = true

[metrics]
  [metrics.prometheus]
    addServicesLabels = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
  prefix           = "traefik"
  exposedByDefault = false

  [providers.consulCatalog.endpoint]
    address = "{{ env "attr.unique.network.ip-address" }}:8500"
    scheme  = "http"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name         = "traefik-api"
        port         = "api"
        address_mode = "host"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "api"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name         = "traefik-grafana"
        port         = "grafana"
        address_mode = "host"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "grafana"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name         = "traefik-prometheus"
        port         = "prometheus"
        address_mode = "host"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "prometheus"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
