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
        image = "grafana/grafana:7.4.2"
        ports = ["grafana_ui"]

        volumes = [
          "local/datasources:/etc/grafana/provisioning/datasources",
          "local/dashboard.json:/var/lib/grafana/dashboards/default/dashboard.json",
          "local/dashboard.yaml:/etc/grafana/provisioning/dashboards/dashboard.yaml",
        ]
      }

      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Editor"
        GF_SERVER_HTTP_PORT        = "$${NOMAD_PORT_grafana_ui}"
      }

      template {
        left_delimiter  = "%%"
        right_delimiter = "%%"

        data        = <<EOF
${grafana_dashboard}
EOF
        destination = "local/dashboard.json"
      }

      template {
        data        = <<EOF
- name: 'default'
  org_id: 1
  folder: ''
  type: 'file'
  options:
    folder: '/var/lib/grafana/dashboards'
EOF
        destination = "local/dashboard.yaml"
      }


      template {
        data        = <<EOH
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://prometheus.service.consul:9090
  isDefault: true
  version: 1
  editable: false
EOH
        destination = "local/datasources/prometheus.yaml"
      }

      resources {
        cpu    = 100
        memory = 64
      }

      service {
        name = "grafana"
        port = "grafana_ui"

        check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"
        }

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.grafana.entrypoints=grafana",
          "traefik.tcp.routers.grafana.rule=HostSNI(`*`)"
        ]
      }
    }
  }
}
