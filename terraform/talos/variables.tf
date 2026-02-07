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

variable "nameservers" {
  description = "The nameservers to use for dns resolution."
  type        = list(any)
  nullable    = false
  # Safe defaults, if you don't want DNS64+NAT64 (and trust google)
  #default     = ["2606:4700:4700::1111", "2606:4700:4700::1001", "1.1.1.1", "8.8.8.8"]
  default = [
    ##
    ## DNS64+NAT64
    ## source: https://stats.uptimerobot.com/GQ5RyTJLKZ
    ##
    # Kasper Dupont Finland
    "2a01:4f9:c010:3f02::1",
    # Kasper Dupont Germany
    "2a01:4f8:c2c:123f::1",
    # Tuxis
    "2a03:7900:2:0:31:3:104:161"
  ]
}
