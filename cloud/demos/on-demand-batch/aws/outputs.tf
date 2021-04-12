output "detail" {
  value = <<CONFIGURATION

Server IPs:
${module.servers.addresses}

The Nomad UI can be accessed at ${module.network.nomad_addr}/ui
The Consul UI can be accessed at ${module.network.consul_addr}/ui
Grafana dashboard can be accessed at http://${module.network.clients_lb_dns_names[0]}:3000/d/CJlc3r_Mk/on-demand-batch-job-demo?orgId=1&refresh=5s
Traefik can be accessed at http://${module.network.clients_lb_dns_names[0]}:8081
Prometheus can be accessed at http://${module.network.clients_lb_dns_names[0]}:9090

CLI environment variables:
export NOMAD_ADDR=${module.network.nomad_addr}
CONFIGURATION
}

output "cleanup" {
  # Only show when requested.
  sensitive = true

  value = <<EOF

Please run the following commands in your terminal:

  aws ec2 deregister-image --image-id ${module.image.id} --region ${var.region}
  aws ec2 delete-snapshot --snapshot-id ${module.image.snapshot_id} --region ${var.region}
EOF
}
