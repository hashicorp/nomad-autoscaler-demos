# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

job "webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 1

    network {
      port "webapp_http" {}
      port "toxiproxy_webapp" {}
    }

    scaling {
      enabled = true
      min     = 1
      max     = 20

      policy {
        cooldown            = "1m"
        evaluation_interval = "30s"

        check "avg_sessions" {
          source = "prometheus"
          query  = "sum(traefik_entrypoint_open_connections{entrypoint=\"webapp\"})/scalar(nomad_nomad_job_summary_running{task_group=\"demo\"})"

          strategy "target-value" {
            target = 10
          }
        }
      }
    }

    task "webapp" {
      driver = "docker"

      config {
        image = "hashicorp/demo-webapp-lb-guide"
        ports = ["webapp_http"]
      }

      env {
        PORT    = "${NOMAD_PORT_webapp_http}"
        NODE_IP = "${NOMAD_IP_webapp_http}"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "webapp"
        port = "webapp_http"

        check {
          type     = "http"
          path     = "/"
          interval = "3s"
          timeout  = "1s"
        }
      }
    }

    task "toxiproxy" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      config {
        image      = "shopify/toxiproxy:2.1.4"
        entrypoint = ["/entrypoint.sh"]
        ports      = ["toxiproxy_webapp"]

        volumes = [
          "local/entrypoint.sh:/entrypoint.sh",
        ]
      }

      template {
        data = <<EOH
#!/bin/sh

set -ex

/go/bin/toxiproxy -host 0.0.0.0  &

while ! wget --spider -q http://localhost:8474/version; do
  echo "toxiproxy not ready yet"
  sleep 0.2
done

/go/bin/toxiproxy-cli create webapp -l 0.0.0.0:${NOMAD_PORT_toxiproxy_webapp} -u ${NOMAD_ADDR_webapp_http}
/go/bin/toxiproxy-cli toxic add -n latency -t latency -a latency=1000 -a jitter=500 webapp
tail -f /dev/null
        EOH

        destination = "local/entrypoint.sh"
        perms       = "755"
      }

      resources {
        cpu    = 100
        memory = 32
      }

      service {
        name = "toxiproxy-webapp"
        port = "toxiproxy_webapp"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.webapp.entrypoints=webapp",
          "traefik.http.routers.webapp.rule=Path(`/`)",
        ]
      }
    }
  }
}
