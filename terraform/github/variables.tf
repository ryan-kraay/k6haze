variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID.  This will be used to determine where to find your S3 bucket."
}

variable "github_owner_slug" {
  description = "The 'owner/organization' can be extracted from the url: ie https://github.com/:owner_slug/:repo_name"
}

variable "github_repo_name" {
  description = "The Github repo name to apply our changes to."
  default     = "k6haze"
}

variable "terraform_statefile_bucket" {
  description = "The name of the S3 bucket which will hold our tfstate file"
}
