
# Install the cilium gateway api crds, must be compatible with cilium gateway-api
#  source: https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/
# TODO:  I don't know how to automate this via renovate
resource "helm_release" "gateway_api_crds" {
  name       = "gateway-api-crds"
  repository = "https://wiremind.github.io/wiremind-helm-charts"
  chart      = "gateway-api-crds"
  version    = "1.4.0"

  namespace        = "kube-system"
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 1
}
