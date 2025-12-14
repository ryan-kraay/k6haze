data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = ["https://${var.master_node.fqdn}:50000"]
  # used by talosctl to contact a member of the cluster
  nodes = [var.master_node.fqdn]
}

resource "local_file" "talosconfig" {
  count = var.export_configs == true ? 1 : 0

  content         = data.talos_client_configuration.this.talos_config
  filename        = "${path.root}/../github/secrets/development-talos/TALOSCONFIG_TEXT.raw"
  file_permission = "0600"
}

