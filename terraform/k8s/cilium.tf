locals {
  # Extract all pod CIDRs from nodes
  pod_cidrs = flatten([for node in var.nodes : node.pod_cidrs])
}

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.20.0"

  namespace        = "kube-system"
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  wait_for_jobs    = true

  max_history = 2

  values = compact([
    # Main Cilium configuration
    yamlencode(yamldecode(<<-YAML
      ##
      ## Basic IPv6 Support
      ##
      operator:
        replicas: ${length(var.nodes) > 2 ? 2 : length(var.nodes)} # The default is two, which doesn't work on a single machine configuration
      # The necessary fields to enable native IPv6
      ipv4:
        enabled: false
      ipv6:
        enabled: true
      routingMode: native
      enableIPv6Masquerade: false
      # Allow Hubble
      hubble:
        relay:
          enabled: true
        ui:
          enabled: true

      ##
      ## Replace kube-proxy with cilium
      ##
      kubeProxyReplacement: true
      k8sServicePort: 6443
      # Disable SNAT infavor of a direct connection (for hostPort)
      #   This will retain the client's ip-address (and improve performance)
      # source: https://docs.cilium.io/en/latest/network/kubernetes/kubeproxy-free/#direct-server-return-dsr-with-ipv4-option-ipv6-extension-header
      loadBalancer:
        mode: dsr
        dsrDispatch: opt

      ##
      ## Enable Gateway API
      ##
      gatewayAPI:
        enabled: true
        gatewayClass:
          create: "true"
        # recommended by talos: https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
        #enableAlpn: true
        #enableAppProtocol: true

      ##
      ## Block all Ingress/Egress by default
      ##
      policyEnforcementMode: "always"

      ##
      ## NDP For LoadBalancers/Services
      ##
      # reference: https://blog.grosdouli.dev/blog/cilium-gateway-api-cert-manager-let's-encrypt
      #externalIPs:  # This does not exist in the chart
      #  enabled: true
      # source: https://docs.cilium.io/en/latest/network/l2-announcements/
      l2announcements:
        enabled: true
      # Should be adjusted for multi-node setups: https://docs.cilium.io/en/latest/network/l2-announcements/#sizing-client-rate-limit
      k8sClientRateLimit:
        burst: 40
        qps: 20
      # source: https://docs.cilium.io/en/latest/network/kubernetes/kubeproxy-free/#neighbor-discovery
      #l2NeighDiscovery:
      #  enabled: true

      ##
      ## Talos Support
      ##
      # IPAM mode for Kubernetes
      ipam:
        mode: kubernetes
      # Security context capabilities
      securityContext:
        capabilities:
          ciliumAgent: [CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID]
          cleanCiliumState: [NET_ADMIN,SYS_ADMIN,SYS_RESOURCE]
      # Cgroup configuration
      cgroup:
        autoMount:
          enabled: false
        hostRoot: /sys/fs/cgroup
    YAML
    )),
    # Tolerations for single-node clusters
    length(var.nodes) < 2 ? yamlencode({
      hubble = {
        relay = {
          tolerations = [{
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect   = "NoSchedule"
          }]
        }
        ui = {
          tolerations = [{
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect   = "NoSchedule"
          }]
        }
      }
    }) : null
  ])

  set_list = [
    {
      name = "ipam.operator.clusterPoolIPv6PodCIDRList"
      # since set_sensitive_list doesn't exist, this parameter
      #  will be exposed in terraform update/destroy
      #  see: https://github.com/hashicorp/terraform-provider-helm/issues/1287
      value = local.pod_cidrs
    }
  ]
  set_sensitive = [
    {
      name = "ipv6NativeRoutingCIDR"
      # TODO: Cilium requires continuous IP ranges - this will cause problems 
      # with multi-node setups using non-continuous pod CIDRs
      value = local.pod_cidrs[0]
    },
    ##
    ## Replace kube-proxy with cilium
    ##
    {
      name  = "k8sServiceHost"
      value = var.cluster.endpoint.ipv6
    }
  ]

  depends_on = [helm_release.gateway_api_crds]
}

