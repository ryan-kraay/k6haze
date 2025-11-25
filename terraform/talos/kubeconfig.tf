resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration

  # endpoint is a derrived from node, but loses the senstive() flag
  node     = data.talos_client_configuration.this.nodes[0]
  endpoint = data.talos_client_configuration.this.nodes[0]
}

resource "local_file" "kubeconfig" {
  count = var.export_configs == true ? 1 : 0

  content = talos_cluster_kubeconfig.this.kubeconfig_raw
  # TODO:  Propigate "production" as a parameter
  filename        = "${path.root}/../github/secrets/development-k8s/kubeconfig"
  file_permission = "0600"
}
