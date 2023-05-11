job "webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 3

    network {
      port "webapp_http" {}
      port "toxiproxy_webapp" {}
      port "toxiproxy" {}
    }

    scaling {
      enabled = true
      min     = 1
      max     = 20

      policy {
        cooldown = "20s"

        check "avg_sessions" {
          source = "prometheus"
          query  = "sum(traefik_entrypoint_open_connections{entrypoint=\"webapp\"} OR on() vector(0))/scalar(nomad_nomad_job_summary_running{exported_job=\"webapp\",task_group=\"demo\"})"

          strategy "target-value" {
            target = 5
          }
        }
      }
    }

    task "webapp" {
      driver = "raw_exec"

    config {
        command = "python3"
        args    = ["-m", "http.server","${NOMAD_PORT_webapp_http}"]
    }

      env {
        PORT    = "${NOMAD_PORT_webapp_http}"
        NODE_IP = "${NOMAD_IP_webapp_http}"
      }

      resources {
        cpu    = 100
        memory = 16
      }
    }

    task "toxiproxy" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      config {
        image = "ghcr.io/shopify/toxiproxy:2.5.0"
        args = [
          "-host", "0.0.0.0",
          "-port", "${NOMAD_PORT_toxiproxy}",
          "-config", "${NOMAD_TASK_DIR}/config.json",
        ]

        ports = [
          "toxiproxy",
          "toxiproxy_webapp",
        ]
      }

      template {
        data        = <<EOF
[
  {
    "name": "webapp",
    "listen": "0.0.0.0:{{env "NOMAD_PORT_toxiproxy_webapp"}}",
    "upstream": "{{env "NOMAD_ADDR_webapp_http"}}",
    "enabled": true
  }
]
EOF
        destination = "${NOMAD_TASK_DIR}/config.json"
      }

      resources {
        cpu    = 50
        memory = 32
      }

      service {
        name     = "webapp"
        provider = "nomad"
        port     = "toxiproxy_webapp"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.webapp.entrypoints=webapp",
          "traefik.http.routers.webapp.rule=PathPrefix(`/`)"
        ]

        check {
          type           = "http"
          path           = "/"
          interval       = "5s"
          timeout        = "3s"
          initial_status = "passing"
        }
      }
    }

    task "toxiproxy-config" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      restart {
        attempts = 50
        delay    = "1s"
        mode     = "delay"
      }

      config {
        image      = "ghcr.io/shopify/toxiproxy:2.5.0"
        entrypoint = ["/toxiproxy-cli"]
        args = [
          "--host", "${NOMAD_ADDR_toxiproxy}",
          "toxic", "add",
          "--toxicName", "latency",
          "--type", "latency",
          "--attribute", "latency=1000",
          "--attribute", "jitter=500",
          "webapp",
        ]
      }
    }
  }
}