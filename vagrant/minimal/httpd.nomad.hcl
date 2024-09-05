# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "httpd" {

  group "web" {

    count = 1

    scaling {
      enabled = true
      min     = 1
      max     = 5

      policy {
        evaluation_interval = "5s"
        cooldown            = "1m"

        check "fixed" {
          strategy "fixed-value" {
            value = 2
          }
        }
      }
    }

    network {
      mode = "bridge"
      port "www" {
        to = 8001
      }
    }

    task "http" {

      driver = "docker"

      config {
        image   = "busybox:1"
        command = "httpd"
        args    = ["-vv", "-f", "-p", "8001", "-h", "/local"]
        ports   = ["www"]
      }

      template {
        data        = "<html>hello, world</html>"
        destination = "${NOMAD_TASK_DIR}/index.html"
      }

      resources {
        cpu    = 100
        memory = 100
      }

    }
  }
}
