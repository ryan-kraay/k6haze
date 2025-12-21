variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID.  This will be used to determine where to find your S3 bucket."
}

variable "terraform_statefile_bucket" {
  description = "The name of the S3 bucket which will hold our tfstate file"
}

variable "cluster_ipv6" {
  description = "a temporary hack"
  sensitive = true
}

variable "cluster_loadbalancer_default_cidrs" {
  description = "a temporary hack"
  type = list(string)
  sensitive = true
}
