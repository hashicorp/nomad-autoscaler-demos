job "grafana" {
  datacenters = ["platform"]

  group "grafana" {
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
          "local/dashboards:/etc/grafana/provisioning/dashboards",
          "local/dashboard.json:/var/lib/grafana/dashboards/default/dashboard.json",
        ]
      }

      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Editor"
        GF_SERVER_HTTP_PORT        = "$${NOMAD_PORT_grafana_ui}"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://{{ range $i, $s := service "prometheus" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
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
  url: http://{{ range $i, $s := service "loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
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
  folder: Nomad Autoscaler Demos
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

      template {
        left_delimiter  = "%%"
        right_delimiter = "%%"

        data        = <<EOF
${grafana_dashboard}
EOF
        destination = "local/dashboard.json"
      }

      resources {
        cpu    = 100
        memory = 64
      }

      service {
        name = "grafana"
        port = "grafana_ui"

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.grafana.entrypoints=grafana",
          "traefik.tcp.routers.grafana.rule=HostSNI(`*`)"
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

  group "loki" {
    network {
      port "loki" {}
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:2.1.0"
        args  = ["--config.file=$${NOMAD_TASK_DIR}/loki.yml"]
        ports = ["loki"]
      }

      template {
        data = <<EOH
---
auth_enabled: false

server:
  http_listen_port: {{ env "NOMAD_PORT_loki" }}

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
  - from: 2020-05-15
    store: boltdb
    object_store: filesystem
    schema: v11
    index:
      prefix: index_
      period: 168h

storage_config:
  boltdb:
    directory: /tmp/loki/index

  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/loki.yml"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name = "loki"
        port = "loki"

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
