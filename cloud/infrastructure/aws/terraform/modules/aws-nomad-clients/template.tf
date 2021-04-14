data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh.tpl")

  vars = {
    consul_binary = var.consul_binary_url
    nomad_binary  = var.nomad_binary_url
    retry_join    = var.retry_join
    node_class    = var.nomad_node_class
  }
}
