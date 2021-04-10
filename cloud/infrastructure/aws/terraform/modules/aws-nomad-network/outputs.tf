# Security groups.
output "agents_sg_id" {
  value = aws_security_group.agents.id
}

output "services_sg_ids" {
  value = aws_security_group.services.*.id
}

# Servers ELB outputs.
output "servers_lb_id" {
  value = aws_elb.servers.id
}

output "servers_lb_dns" {
  value = aws_elb.servers.dns_name
}

output "servers_lb_zone_id" {
  value = aws_elb.servers.zone_id
}

# Services ELBs outputs.
output "services_lb_ids" {
  value = aws_elb.services.*.id
}

output "services_lb_dns_names" {
  value = aws_elb.services.*.dns_name
}

output "services_lb_names" {
  value = aws_elb.services.*.name
}

output "services_lb_zone_ids" {
  value = aws_elb.services.*.zone_id
}

# Nomad and Consul address.
output "consul_addr" {
  value = "http://${aws_elb.servers.dns_name}:8500"
}

output "nomad_addr" {
  value = "http://${aws_elb.servers.dns_name}:4646"
}
