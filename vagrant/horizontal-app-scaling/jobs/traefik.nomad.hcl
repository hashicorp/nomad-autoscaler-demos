job "traefik" {
  datacenters = ["dc1"]

  group "traefik" {
    count = 1

    network {
      port "admin" {
        static = 8081
      }
      port "grafana" {
        static = 3000
      }
      port "prometheus" {
        static = 9090
      }
      port "webapp" {
        static = 8000
      }
    }

    service {
      name     = "traefik-admin"
      provider = "nomad"
      port     = "admin"
      tags = [
        "metrics"
      ]

      check {
        type     = "http"
        path     = "/ping"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"
      config {
        image        = "traefik:v3.0"
        ports        = ["admin", "grafana", "prometheus", "webapp"]

        args = [
          "--api.dashboard=true",
          "--api.insecure=true",
          "--entrypoints.grafana.address=:${NOMAD_PORT_grafana}",
          "--entrypoints.prometheus.address=:${NOMAD_PORT_prometheus}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",
          "--entrypoints.webapp.address=:${NOMAD_PORT_webapp}",
          "--metrics.prometheus=true",
          "--metrics.prometheus.addServicesLabels=true",
          "--ping=true",
          "--providers.nomad=true",
          "--providers.nomad.exposedByDefault=false",
          "--providers.nomad.endpoint.address=http://host.docker.internal:4646"
        ]
      }
    }
  }
}
