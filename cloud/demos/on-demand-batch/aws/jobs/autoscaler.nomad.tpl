job "autoscaler" {
  datacenters = ["dc1"]

  constraint {
    attribute = "$${node.class}"
    value     = "platform"
  }

  group "autoscaler" {
    network {
      port "autoscaler" {}
      port "promtail" {}
    }

    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler:0.3.2"
        command = "nomad-autoscaler"
        args    = ["agent", "-config", "local/config.hcl"]
        ports   = ["autoscaler"]
      }

      template {
        data = <<EOF
http {
  bind_address = "0.0.0.0"
  bind_port    = {{ env "NOMAD_PORT_autoscaler" }}
}

policy {
  dir = "local/policies"
}

nomad {
  address = "http://{{env "attr.unique.network.ip-address" }}:4646"
}

apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "http://{{ range service "prometheus" }}{{ .Address }}:{{ .Port }}{{ end }}"
  }
}

target "aws-asg" {
  driver = "aws-asg"
  config = {
    aws_region = "${aws_region}"
  }
}

strategy "pass-through" {
  driver = "pass-through"
}
EOF

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config.hcl"
      }

      template {
        data = <<EOF
scaling "batch" {
  enabled = true
  min     = 0
  max     = 5

  policy {
    cooldown            = "1m"
    evaluation_interval = "10s"

    check "batch_jobs_in_progess" {
      source = "prometheus"
      query  = "sum(nomad_nomad_job_summary_queued{exported_job=~\"batch/.*\"} + nomad_nomad_job_summary_running{exported_job=~\"batch/.*\"}) OR on() vector(0)"

      strategy "pass-through" {}
    }

    target "aws-asg" {
      aws_asg_name           = "${aws_asg_name}"
      node_class             = "batch"
      node_drain_deadline    = "1h"
      node_selector_strategy = "empty_ignore_system"
    }
  }
}
        EOF

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/policies/batch.hcl"
      }

      service {
        name = "autoscaler"
        port = "autoscaler"

        check {
          type     = "http"
          path     = "/v1/health"
          interval = "10s"
          timeout  = "2s"
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
      __path__: {{ env "NOMAD_ALLOC_DIR" }}/logs/autoscaler*
  pipeline_stages:
  - match:
      selector: '{task="autoscaler"}'
      stages:
      - regex:
          expression: '.*policy_id=(?P<policy_id>[a-zA-Z0-9_-]+).*reason="(?P<reason>.+)"'
      - labels:
          policy_id:
          reason:
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
