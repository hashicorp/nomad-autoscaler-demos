job "das-autoscaler" {
  datacenters = ["dc1"]

  group "autoscaler" {
    count = 1

    network {
      port "http" {}
    }

    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler-enterprise:0.3.4"
        command = "nomad-autoscaler"
        ports   = ["http"]

        args = [
          "agent",
          "-config",
          "local/autoscaler.hcl",
          "-http-bind-address",
          "0.0.0.0",
          "-http-bind-port",
          "${NOMAD_PORT_http}",
        ]
      }

      template {
        destination = "local/autoscaler.hcl"

        data = <<EOH
// Set the address of the Nomad agent. This can be omitted and in this example
// is set to the default for clarity.
nomad {

  // Use Consul service discovery for the Nomad client IP and Port.
  address = "{{ with service "nomad-client" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"

  // Use the slapt operator so the autoscaler monitors scaling policies from
  // all Nomad namespaces. If you wish to have it only monitor a single
  // namespace, update this param to match the desired name.
  namespace = "*"

  // If Nomad ALCs are in use, the following line should be uncommented and
  // updated to include an ACL token.
  // token = ""
}

// Setup the Prometheus APM so that the autoscaler can pull historical and
// point-in-time metrics regarding task resource usage.
apm "prometheus" {
  driver = "prometheus"
  config = {

    // Use Consul service discovery for the Prometheus IP and Port.
    address = "{{ with service "prometheus" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"

    // If you wish to use this example without Consul, you can remove the above
    // Consul service discovery address section and replace it with the line
    // below uncommented with an updated endpoint if required.
    // address = "http://localhost:9090"
  }
}

// This block contains configuration options specific to the Dynamic Application
// Sizing enterprise feature.
dynamic_application_sizing {

  // Lower the evaluate interval so we can reproduce recommendations after only
  // 5 minutes, rather than having to wait for 24hrs as is the default.
  evaluate_after = "5m"
}

policy_eval {

  // Disable the horizontal application and horizontal cluster workers. This
  // helps reduce log noise during the demo.
  workers = {
    cluster    = 0
    horizontal = 0
  }
}
EOH
      }

      resources {
        cpu    = 512
        memory = 512
      }

      service {
        name = "autoscaler"
        port = "http"

        check {
          type     = "http"
          path     = "/v1/health"
          interval = "5s"
          timeout  = "2s"
        }
      }
    }
  }
}
