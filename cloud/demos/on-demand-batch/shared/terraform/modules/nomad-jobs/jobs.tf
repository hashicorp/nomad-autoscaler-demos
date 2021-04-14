data "local_file" "grafana_dashboard" {
  filename = "${path.module}/files/grafana_dashboard.json"
}

resource "null_resource" "wait_for_nomad_api" {
  provisioner "local-exec" {
    command = "while ! nomad server members > /dev/null 2>&1; do echo 'waiting for nomad api...'; sleep 10; done"
    environment = {
      NOMAD_ADDR = var.nomad_addr
    }
  }
}

resource "nomad_job" "batch" {
  depends_on = [null_resource.wait_for_nomad_api]

  jobspec = file("${path.module}/jobs/batch.nomad")
}

resource "nomad_job" "grafana" {
  depends_on = [null_resource.wait_for_nomad_api]

  jobspec = templatefile(
    "${path.module}/jobs/grafana.nomad.tpl",
    {
      grafana_dashboard = data.local_file.grafana_dashboard.content,
    }
  )
}

resource "nomad_job" "traefik" {
  depends_on = [null_resource.wait_for_nomad_api]

  jobspec = file("${path.module}/jobs/traefik.nomad")
}

resource "nomad_job" "prometheus" {
  depends_on = [null_resource.wait_for_nomad_api]

  jobspec = file("${path.module}/jobs/prometheus.nomad")
}
