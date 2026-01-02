locals {
  talos_version = "v${var.talos_version}"
  # Get the first controlplane node's FQDN for cluster endpoint
  cluster_fqdn     = [for node in var.nodes : node.fqdn if node.is_controlplane][0]
  cluster_endpoint = "https://${local.cluster_fqdn}:6443"
}

# Constructs all the CA's to connect to Talos
resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

data "talos_machine_configuration" "this" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
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
          podSubnets     = sort(flatten([for node in var.nodes : node.pod_cidrs]))
          serviceSubnets = sort(flatten([for node in var.nodes : node.service_cidrs]))
        }
        proxy = {
          # use the cilium replacement for kube-proxy
          # https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
          disabled = true
        }
        controllerManager = {
          extraArgs = {
            # as near as I can tell, this MUST be less than our podCIDRs
            #  as a portion of the podCIDRs will be reserved for nodes and
            #  critical pods.
            # source: https://wenhan.blog/en/posts/20220126_--node-cidr-mask-size_error/
            node-cidr-mask-size = "120"
            # by default it uses 127.0.0.1, but we want ipv6
            #  ...and hope it won't break monitoring:
            #  `https://[::1]:10257/metrics`
            bind-address = "::1"
          }
        }
        # Increase etcd timeouts for high disk latency environments
        # VPS storage can have random latency spikes that cause etcd failures
        # See: https://etcd.io/docs/v3.4/tuning/
        etcd = {
          extraArgs = {
            heartbeat-interval = "500"  # Default: 100ms, increase for slow disks
            election-timeout   = "5000" # Default: 1000ms, should be 5-10x heartbeat
          }
        }
        scheduler = {
          extraArgs = {
            bind-address = "::1"
          }
        }
        allowSchedulingOnControlPlanes = true
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  # we need to temporarily cast-off our sensitive flag, so we can use hostname as a key
  for_each = { for node in nonsensitive(var.nodes) : node.hostname => sensitive(node) }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration

  node     = each.value.fqdn
  endpoint = each.value.fqdn

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = "ghcr.io/siderolabs/installer:${local.talos_version}"
          disk  = "/dev/vda"
          wipe  = true
        },
        network = {
          hostname    = each.value.hostname
          interfaces  = each.value.interfaces
          nameservers = ["2606:4700:4700::1111", "2606:4700:4700::1001", "1.1.1.1", "8.8.8.8"]
        }
        # exposes the talos endpoint
        #  it's unclear if this should refer to the control nodes, each node, or all nodes.
        certSANs = [each.value.fqdn]
      }
    })
  ]
}

moved {
  from = talos_machine_configuration_apply.this
  to   = talos_machine_configuration_apply.this["shed"]
}

resource "talos_machine_bootstrap" "this" {
  # we need to temporarily cast-off our sensitive flag, so we can use hostname as a key
  for_each = { for node in nonsensitive(var.nodes) : node.hostname => sensitive(node) }

  depends_on = [
    talos_machine_configuration_apply.this
  ]

  node     = each.value.fqdn
  endpoint = each.value.fqdn

  client_configuration = talos_machine_secrets.this.client_configuration
}

moved {
  from = talos_machine_bootstrap.this
  to   = talos_machine_bootstrap.this["shed"]
}
