data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh.tpl")

  vars = {
    consul_binary = var.consul_binary_url
    nomad_binary  = var.nomad_binary_url
    server_count  = var.instance_count
    retry_join    = var.retry_join
  }
}
