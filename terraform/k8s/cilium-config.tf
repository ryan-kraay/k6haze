resource "helm_release" "cilium_config" {
  name  = "cilium-config"
  chart = "./charts/cilium-config"

  namespace        = "kube-system"
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  wait_for_jobs    = true

  max_history = 2

  values = [
    yamlencode({
      loadBalancer = {
        defaultCIDRs   = var.cluster_loadbalancer_default_cidrs
        dualstackCIDRs = []               # Empty by default, won't create resource
      }
      gateway = {
        CIDRs = var.cluster_gateway_cirds
      }
    })
  ]

  depends_on = [helm_release.cilium]
}
