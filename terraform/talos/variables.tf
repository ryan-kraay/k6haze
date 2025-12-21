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
