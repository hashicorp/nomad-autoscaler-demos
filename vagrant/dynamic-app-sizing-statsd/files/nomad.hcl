// Setup some default parameters, including data_dir which is required.
datacenter = "dc1"
data_dir   = "/opt/nomad"

// Enable to Nomad agent to run in server, only expecting itself as a server in
// the raft pool.
server {
  enabled          = true
  bootstrap_expect = 1
}

// Enable the Nomad agent to run in client mode.
client {
  enabled = true
}

// Enable allocation and node metrics telemetry as well as expose them via the
// API in Prometheus format.
telemetry {
  disable_hostname           = true
  datadog_address            = "localhost:8125"
  publish_allocation_metrics = true
  publish_node_metrics       = true
}
