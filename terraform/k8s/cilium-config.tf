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
        defaultCIDRs   = var.cluster.loadbalancer.default_cidrs
        dualstackCIDRs = [] # Empty by default, won't create resource
      }
      gateway = {
        # Extract all IPv6 gateways from node routes and format as /128 CIDRs
        CIDRs = sort(distinct(flatten([
          for node in var.nodes : [
            for interface in node.interfaces : [
              for route in interface.routes :
              "${route.gateway}/128"
              if strcontains(route.gateway, ":")
            ]
          ]
        ])))
      }
    })
  ]

  depends_on = [helm_release.cilium]
}
