job "autoscaler" {
  type = "service"

  datacenters = ["dc1"]

  group "autoscaler" {
    count = 1

    network {
      port "http" {}
      port "promtail" {}
    }

    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler:0.3.4"
        command = "nomad-autoscaler"
        ports   = ["http"]

        args = [
          "agent",
          "-config",
          "${NOMAD_TASK_DIR}/config.hcl",
          "-http-bind-address",
          "0.0.0.0",
          "-http-bind-port",
          "${NOMAD_PORT_http}",
        ]
      }

      ## Alternatively, you could also run the Autoscaler using the exec driver
      # driver = "exec"
      #
      # config {
      #   command = "/usr/local/bin/nomad-autoscaler"
      #   args    = ["agent", "-config", "${NOMAD_TASK_DIR}/config.hcl"]
      # }
      #
      # artifact {
      #   source      = "https://releases.hashicorp.com/nomad-autoscaler/0.3.2/nomad-autoscaler_0.3.2_linux_amd64.zip"
      #   destination = "/usr/local/bin"
      # }

      template {
        data = <<EOF
nomad {
  address = "http://{{env "attr.unique.network.ip-address" }}:4646"
}

telemetry {
  prometheus_metrics = true
  disable_hostname   = true
}

apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "http://{{ env "attr.unique.network.ip-address" }}:9090"
  }
}

strategy "target-value" {
  driver = "target-value"
}
          EOF

        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      resources {
        cpu    = 50
        memory = 128
      }

      service {
        name = "autoscaler"
        port = "http"

        check {
          type     = "http"
          path     = "/v1/health"
          interval = "3s"
          timeout  = "1s"
        }
      }
    }

    task "promtail" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      config {
        image = "grafana/promtail:1.5.0"
        ports = ["promtail"]

        args = [
          "-config.file",
          "local/promtail.yaml",
        ]
      }

      template {
        data = <<EOH
server:
  http_listen_port: {{ env "NOMAD_PORT_promtail" }}
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

client:
  url: http://{{ range $i, $s := service "loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}/api/prom/push

scrape_configs:
- job_name: system
  entry_parser: raw
  static_configs:
  - targets:
      - localhost
    labels:
      task: autoscaler
      __path__: /alloc/logs/autoscaler*
  pipeline_stages:
  - match:
      selector: '{task="autoscaler"}'
      stages:
      - regex:
          expression: '.*policy_id=(?P<policy_id>[a-zA-Z0-9_-]+).*source=(?P<source>[a-zA-Z0-9_-]+).*strategy=(?P<strategy>[a-zA-Z0-9_-]+).*target=(?P<target>[a-zA-Z0-9_-]+).*Group:(?P<group>[a-zA-Z0-9]+).*Job:(?P<job>[a-zA-Z0-9_-]+).*Namespace:(?P<namespace>[a-zA-Z0-9_-]+)'
      - labels:
          policy_id:
          source:
          strategy:
          target:
          group:
          job:
          namespace:
EOH

        destination = "local/promtail.yaml"
      }

      resources {
        cpu    = 50
        memory = 32
      }

      service {
        name = "promtail"
        port = "promtail"

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
