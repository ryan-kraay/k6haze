locals {
  talos_version = "v${var.talos_version}"
}

# Constructs all the CA's to connect to Talos
resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

data "talos_machine_configuration" "this" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.master_node.fqdn}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = local.talos_version
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration

  # endpoint is derrived from node, but misses the sensitive() flag
  node     = var.master_node.fqdn
  endpoint = var.master_node.fqdn

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = "ghcr.io/siderolabs/installer:${local.talos_version}"
          disk  = "/dev/vda"
          wipe  = true
        },
        network = {
          hostname = var.master_node.hostname
          interfaces = [
            {
              interface = "ens3"
              addresses = var.master_node.ipaddresses
              routes = [{
                network = "0.0.0.0/0"
                gateway = var.master_node.gateway
              }]
            }
          ]
        },
        # exposes the talos endpoint
        certSANs = [var.master_node.fqdn]
      }
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]

  # endpoint is derrived from node, but misses the sensitive() flag
  node     = var.master_node.fqdn
  endpoint = var.master_node.fqdn

  client_configuration = talos_machine_secrets.this.client_configuration
}
