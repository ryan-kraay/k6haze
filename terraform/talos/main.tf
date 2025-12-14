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

  config_patches = [
    yamlencode({
      cluster = {
        network = {
          cni = {
            # allows us to install cilium
            name = "none"
          }
        }
        proxy = {
          # use the cilium replacement for kube-proxy
          # https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
          disabled = true
        }
      }
    })
  ]
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
          hostname    = var.master_node.hostname
          interfaces  = var.master_node.interfaces
          nameservers = ["2606:4700:4700::1111", "2606:4700:4700::1001", "1.1.1.1", "8.8.8.8"]
        }
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
