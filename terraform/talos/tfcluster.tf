#
# A shared definition between terraform/talos and terraform/k8s
#
variable "cluster" {
  description = "Cluster-wide configuration"
  type = object({
    endpoint = object({
      fqdn = string
      ipv6 = string
    })
    loadbalancer = object({
      default_cidrs = list(string)
      public_cidrs  = list(string)
    })
  })
  nullable = false
  sensitive = true

  validation {
    condition     = length(var.cluster.loadbalancer.default_cidrs) > 0
    error_message = "cluster.loadbalancer.default_cidrs cannot be empty."
  }
}

variable "nodes" {
  description = "List of all cluster nodes (controlplanes and workers)"
  type = list(object({
    hostname        = string
    fqdn            = string
    is_controlplane = bool
    interfaces = list(object({
      interface = string
      addresses = list(string)
      routes = list(object({
        network = string
        gateway = string
      }))
    }))
    pod_cidrs     = list(string)
    service_cidrs = list(string)
  }))
  sensitive = true
}
