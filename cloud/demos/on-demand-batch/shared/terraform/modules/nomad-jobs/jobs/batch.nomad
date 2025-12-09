# Copyright IBM Corp. 2020, 2024
# SPDX-License-Identifier: MPL-2.0

job "batch" {
  datacenters = ["batch_workers"]
  type        = "batch"

  parameterized {
    meta_optional = ["sleep", "splay"]
  }

  meta {
    sleep = "180"
    splay = "60"
  }

  group "batch" {
    task "sleep" {
      driver = "docker"

      config {
        image   = "alpine:3.13"
        command = "/bin/ash"
        args    = ["${NOMAD_TASK_DIR}/sleep.sh"]
      }

      template {
        data = <<EOF
#!/usr/bin/env bash
dur=$((${NOMAD_META_sleep} + RANDOM % ${NOMAD_META_splay}))
echo "Sleeping for ${dur}s"
sleep $dur
echo "Done"
        EOF

        destination = "local/sleep.sh"
      }

      resources {
        cpu    = 100
        memory = 1500
      }
    }
  }
}
