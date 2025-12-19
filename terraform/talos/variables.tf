variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID.  This will be used to determine where to find your S3 bucket."
}

variable "terraform_statefile_bucket" {
  description = "The name of the S3 bucket which will hold our tfstate file"
}

variable "export_configs" {
  description = "Create the talosconfig and kubeconfig files"
  default     = false
  type        = bool
}

variable "talos_version" {
  description = "The version of talos to deploy"
  nullable    = false
}

variable "cluster_name" {
  description = "The name of this kubernetes cluster"
}

variable "master_node" {
  description = "Describe the master node"
  type = object({
    hostname = string
    fqdn     = string
    interfaces = list(object({
      interface = string
      addresses = list(string)
      routes = list(object({
        network = string
        gateway = string
      }))
    }))
  })
  sensitive = true
}

variable "nodes" {
  description = "List of all cluster nodes (masters and workers)"
  type = list(object({
    hostname = string
    fqdn     = string
    is_master = bool
    interfaces = list(object({
      interface = string
      addresses = list(string)
      routes = list(object({
        network = string
        gateway = string
      }))
    }))
    pod_cidrs = list(string)
    service_cidrs = list(string)
  }))
  sensitive = true
}
