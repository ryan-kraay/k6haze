locals {
  flux_namespace = "flux-system"
}

data "tls_public_key" "flux" {
  private_key_openssh = var.flux_private_key
}

resource "helm_release" "flux_config" {
  name  = "flux-config"
  chart = "./charts/flux-config"

  namespace        = local.flux_namespace
  create_namespace = true
  cleanup_on_fail  = false # We want to keep our flux namespace
  atomic           = true
  wait             = true
  wait_for_jobs    = true

  set_sensitive = [
    {
      name  = "repo.privateKey"
      value = var.flux_private_key
    },
    {
      name  = "repo.publicKey"
      value = trimspace(data.tls_public_key.flux.public_key_openssh)
    },
    {
      name  = "repo.knownHosts"
      value = var.flux_known_hosts
    },
    {
      name  = "repo.ageKey"
      value = var.flux_age
    },
  ]

  # We need the cilium CRDs
  depends_on = [helm_release.cilium_config]
}

resource "helm_release" "flux" {
  name       = "fluxcd-community"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = "2.18.1"

  namespace        = local.flux_namespace
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  upgrade_install  = true
  wait             = true
  wait_for_jobs    = true

  max_history = 2
  values = [
    yamlencode({
      imageAutomationController = {
        create = false
      },
      imageReflectionController = {
        create = false
      },
      kustomizeController = {
        container = {
          # https://fluxcd.io/flux/components/kustomize/kustomizations/#post-build-variable-substitution
          additionalArgs = ["--feature-gates=StrictPostBuildSubstitutions=true"]
        }
      }
    })
  ]

  depends_on = [helm_release.flux_config]
}

#
# Our bootstrap into flux
#
resource "helm_release" "flux_homelab" {
  name       = "homelab"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = "1.14.3"

  namespace        = local.flux_namespace
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  upgrade_install  = true
  wait             = true
  wait_for_jobs    = true

  max_history = 2

  values = [
    yamlencode({
      gitRepository = {
        spec = {
          # Created/managed in flux-config
          secretRef = {
            name = "repo-access"
          }
        }
      }
    })
  ]

  set_sensitive = [
    {
      name  = "gitRepository.spec.ref.branch"
      value = var.flux_sync.branch
    },
    {
      name  = "gitRepository.spec.url"
      value = var.flux_sync.url
    },
    {
      name  = "kustomization.spec.path"
      value = var.flux_sync.path
    },
    {
      name  = "kustomization.spec.postBuild.substitute.root_domain"
      value = var.root_domain
    }
  ]
  depends_on = [helm_release.flux]
}
