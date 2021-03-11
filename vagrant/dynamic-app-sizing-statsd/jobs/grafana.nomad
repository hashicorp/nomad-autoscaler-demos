job "grafana" {
  datacenters = ["dc1"]

  group "grafana" {
    count = 1

    network {
      port "grafana_ui" {
        static = 3000
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:7.4.2"
        ports = ["grafana_ui"]

        volumes = [
          "local/datasources:/etc/grafana/provisioning/datasources",
          "local/dashboards/config:/etc/grafana/provisioning/dashboards",
          "local/dashboards/src/vm-dashboard.json:/var/lib/grafana/dashboards/default/vm-dashboard.json",
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
- name: Victoria Metrics
  type: prometheus
  access: proxy
  url: http://{{ range $i, $s := service "victoriametrics" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: true
  version: 1
  editable: false
EOH

        destination = "local/datasources/victoriametrics.yaml"
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

        destination = "local/dashboards/config/nomad-autoscaler.yaml"
      }

      template {
        data        = file("./files/vm-dashboard.json")
        destination = "local/dashboards/src/vm-dashboard.json"
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
      }
    }
  }
}
