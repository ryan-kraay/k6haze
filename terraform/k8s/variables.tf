variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID.  This will be used to determine where to find your S3 bucket."
}

variable "terraform_statefile_bucket" {
  description = "The name of the S3 bucket which will hold our tfstate file"
}

variable "flux_sync" {
  description = "A git repo for flux to sync against"
  type = object({
    url    = string
    branch = string
    path   = string
  })
  nullable  = false
  sensitive = true

}

variable "flux_private_key" {
  description = "A private ssh key to access flux_sync.url"
  nullable    = false
  sensitive   = true
}

variable "flux_age" {
  description = "An age key used to decrypt secrets stored in flux_sync.url"
  nullable    = false
  sensitive   = true
}

variable "flux_known_hosts" {
  description = "The known_hosts for our flux repo"
  nullable    = false
  sensitive   = true
}

variable "root_domain" {
  description = "Flux will host various domains (ie: www).  These will exist _under_ the root_domain (ie: example.com)"
  nullable    = false
  sensitive   = true
}
