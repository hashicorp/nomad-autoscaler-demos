job "prometheus" {
  datacenters = ["dc1"]

  group "prometheus" {
    count = 1

    network {
      port "prometheus_ui" {}
    }

    task "prometheus" {
      driver = "docker"
     // network_mode = "host"
      config {
        image = "prom/prometheus:latest"
        ports = ["prometheus_ui"]

         args = [
          "--config.file=${NOMAD_TASK_DIR}/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.listen-address=0.0.0.0:${NOMAD_PORT_prometheus_ui}",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
        ] 

        volumes = [
          "local/config:/etc/prometheus/config",
        ]
      }

      template {
        data = <<EOH
---
global:
  scrape_interval:     1s
  evaluation_interval: 1s

scrape_configs:
  - job_name: 'nomad_sd'
    nomad_sd_configs:
      - server: 'http://host.docker.internal:4646'
    relabel_configs:
      - source_labels: ['__meta_nomad_tags']
        regex: '(.*),metrics,(.*)'
        action: keep
      - source_labels: [__meta_nomad_service]
        target_label: job
  - job_name: nomad_autoscaler
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
    static_configs:
      - targets: [{{ range nomadService "autoscaler" }}'{{ .Address }}:{{ .Port }}',{{ end }}]
  - job_name: nomad
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
    static_configs:
    - targets: [host.docker.internal:4646]
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name     = "prometheus"
        provider = "nomad"
        port     = "prometheus_ui"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.prometheus.entrypoints=prometheus",
          "traefik.http.routers.prometheus.rule=PathPrefix(`/`)"
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
