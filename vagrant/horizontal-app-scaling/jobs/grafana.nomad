# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "grafana" {
  datacenters = ["dc1"]

  group "grafana" {
    count = 1

    network {
      port "grafana_ui" {}
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:9.5.2"
        ports = ["grafana_ui"]

        volumes = [
          "local/datasources:/etc/grafana/provisioning/datasources",
          "local/dashboards:/etc/grafana/provisioning/dashboards",
          "~/go/src/github.com/hashicorp/nomad-autoscaler-demos/vagrant/horizontal-app-scaling/files:/var/lib/grafana/dashboards",
        ]
      }

      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Editor"
        GF_SERVER_HTTP_PORT        = "${NOMAD_PORT_grafana_ui}"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://{{ range $i, $s := nomadService "prometheus" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: true
  version: 1
  editable: false
EOH

        destination = "local/datasources/prometheus.yaml"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Loki
  type: loki
  access: proxy
  url: http://{{ range $i, $s := nomadService "loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: false
  version: 1
  editable: false
EOH

        destination = "local/datasources/loki.yaml"
      }

      template {
        data = <<EOH
apiVersion: 1

providers:
- name: Nomad Autoscaler
  folder: Nomad
  folderUid: nomad
  type: file
  disableDeletion: true
  editable: false
  allowUiUpdates: false
  options:
    path: /var/lib/grafana/dashboards
EOH

        destination = "local/dashboards/nomad-autoscaler.yaml"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name     = "grafana"
        provider = "nomad"
        port     = "grafana_ui"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.grafana.entrypoints=grafana",
          "traefik.http.routers.grafana.rule=PathPrefix(`/`)"
        ]

         check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"
        } 
      }
    }
  }
}