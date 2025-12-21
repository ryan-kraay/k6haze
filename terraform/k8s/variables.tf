variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID.  This will be used to determine where to find your S3 bucket."
}

variable "terraform_statefile_bucket" {
  description = "The name of the S3 bucket which will hold our tfstate file"
}

variable "cluster_ipv6" {
  description = "a temporary hack"
}
