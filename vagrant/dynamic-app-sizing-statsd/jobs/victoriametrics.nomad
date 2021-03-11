job "victoriametrics" {
  datacenters = ["dc1"]
  type        = "service"

  group "victoriametrics" {
    count = 1

    network {
      port "http" {
        static = 8428
        to     = 8428
      }
    }

    task "victoriametrics" {
      driver = "docker"

      config {
        image = "victoriametrics/victoria-metrics:v1.55.1"
        args = [
          "-maxConcurrentInserts=128",
          "-insert.maxQueueDuration=2m0s"
        ]
        ports = ["http"]
      }

      service {
	name = "victoriametrics"
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
