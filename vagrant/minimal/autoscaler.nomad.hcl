# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "autoscaler" {

  group "autoscaler" {

    network {
      port "http" {}
    }

    task "autoscaler" {

      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler:0.4.5"
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

      # ALTERNATELY: use the exec2 driver

      # driver = "exec2"

      # config {
      #   command = "/usr/local/bin/nomad-autoscaler"
      #   args = [
      #     "agent",
      #     "-config",
      #     "${NOMAD_TASK_DIR}/config.hcl",
      #     "-http-bind-address",
      #     "0.0.0.0",
      #     "-http-bind-port",
      #     "${NOMAD_PORT_http}",
      #   ]
      # }

      identity {
        env = true
      }

      template {
        data = <<EOF
log_level = "debug"

nomad {
  address = "unix://{{ env "NOMAD_SECRETS_DIR" }}/api.sock"
}

strategy "fixed-value" {
  driver = "fixed-value"
}
          EOF

        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      resources {
        cpu    = 50
        memory = 128
      }

    }
  }
}
