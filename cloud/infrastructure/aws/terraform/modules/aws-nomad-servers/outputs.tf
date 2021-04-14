output "addresses" {
  value = join(
    "\n",
    formatlist(
      " * instance %v - Public: %v, Private: %v",
      aws_instance.servers.*.tags.Name,
      aws_instance.servers.*.public_ip,
      aws_instance.servers.*.private_ip
  ))
}

output "hosts_file" {
  value = join(
    "\n",
    concat(
      formatlist(
        " %-16s  %v.hs",
        aws_instance.servers.*.public_ip,
        aws_instance.servers.*.tags.Name
  )))
}

output "ids" {
  value = aws_instance.servers.*.id
}

output "names" {
  value = aws_instance.servers.*.tags.Name
}

output "private_ips" {
  value = aws_instance.servers.*.private_ip
}

output "public_ips" {
  value = aws_instance.servers.*.public_ip
}

output "ssh_config_file" {
  value = join(
    "\n",
    concat(
      formatlist(
        "Host %v.hs\n  User ubuntu\n  HostName %v\n",
        aws_instance.servers.*.tags.Name,
        aws_instance.servers.*.public_dns
  )))
}
