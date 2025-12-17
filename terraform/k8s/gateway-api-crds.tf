
# Install the cilium gateway api crds, must be compatible with cilium gateway-api
#  source: https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/
# TODO:  I don't know how to automate this via renovate
resource "helm_release" "gateway_api_crds" {
  name       = "cilium-gateway-api-crds"
  repository = "https://wiremind.github.io/wiremind-helm-charts"
  chart      = "gateway-api-crds"
  version    = "1.3.0"

  namespace = "cilium"
  create_namespace = true
  cleanup_on_fail = true
  atomic = true
  max_history = 1

#  set = [
#    {
#      name  = "cluster.enabled"
#      value = "true"
#    },
#    {
#      name  = "metrics.enabled"
#      value = "true"
#    },
#    {
#      name  = "service.annotations.prometheus\\.io/port"
#      value = "9127"
#      type  = "string"
#    }
#  ]
}
