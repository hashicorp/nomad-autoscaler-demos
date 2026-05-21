# Copyright IBM Corp. 2020, 2026
# SPDX-License-Identifier: MPL-2.0

job "webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 3

    network {
      port "webapp_http" {}
      port "toxiproxy_webapp" {}
      # Toxiproxy's admin API. We let Nomad assign a port instead of using the
      # default 8474 so that multiple allocations can run on the same host
      # under network_mode = "host" without colliding.
      port "toxiproxy_admin" {}
    }

    scaling {
      enabled = false
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
        cpu    = 100
        memory = 16
      }
    }

    # Toxiproxy is split into two prestart tasks:
    #   1. "toxiproxy" runs the server (sidecar=true) so it stays up for the
    #      lifetime of the webapp task.
    #   2. "toxiproxy-setup" downloads the toxiproxy CLI and configures the
    #      proxy + latency toxic, then exits (sidecar=false).
    #
    # The current ghcr.io/shopify/toxiproxy image is built FROM scratch, so it
    # has no shell and no toxiproxy-cli binary inside the container; the setup
    # work is therefore done from a sibling exec task that fetches the CLI via
    # an artifact block. network_mode = "host" on the docker task lets the exec
    # sibling reach the toxiproxy admin API on localhost:8474.
    task "toxiproxy" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      config {
        image        = "ghcr.io/shopify/toxiproxy:2.12.0"
        ports        = ["toxiproxy_webapp", "toxiproxy_admin"]
        network_mode = "host"
        args = [
          "-host=0.0.0.0",
          "-port=${NOMAD_PORT_toxiproxy_admin}",
        ]
      }

      resources {
        cpu    = 100
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

    task "toxiproxy-setup" {
      driver = "exec"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      # Multi-arch: ${attr.cpu.arch} is "amd64" or "arm64", which matches the
      # filename suffix used by upstream toxiproxy releases.
      artifact {
        source      = "https://github.com/Shopify/toxiproxy/releases/download/v2.12.0/toxiproxy-cli-linux-${attr.cpu.arch}"
        destination = "local/toxiproxy-cli"
        mode        = "file"
      }

      template {
        data = <<EOH
#!/bin/sh
set -e

chmod +x local/toxiproxy-cli

export TOXIPROXY_URL=http://localhost:{{ env "NOMAD_PORT_toxiproxy_admin" }}

until local/toxiproxy-cli list > /dev/null 2>&1; do
  echo "waiting for toxiproxy server..."
  sleep 0.2
done

local/toxiproxy-cli create -l 0.0.0.0:{{ env "NOMAD_PORT_toxiproxy_webapp" }} -u {{ env "NOMAD_ADDR_webapp_http" }} webapp
local/toxiproxy-cli toxic add -n latency -t latency -a latency=1000 -a jitter=500 webapp
        EOH

        destination = "local/setup.sh"
        perms       = "755"
      }

      config {
        command = "local/setup.sh"
      }

      resources {
        cpu    = 50
        memory = 32
      }
    }
  }
}
