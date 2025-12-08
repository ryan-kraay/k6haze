terraform {
  # source: https://developers.cloudflare.com/terraform/advanced-topics/remote-backend/
  backend "s3" {
    bucket                      = var.terraform_statefile_bucket
    key                         = "github.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
    access_key                  = ""
    secret_key                  = ""
    endpoints                   = { s3 = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com" }
  }
  required_providers {
    # Necessary to acces S3 tfstate
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.14.0"
    }
    # Necessary to decrypt local secrets
    sops = {
      source  = "carlpett/sops"
      version = "1.3.0"
    }
    # necessary to modify our gitrepo
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
  }
}

# Set CLOUDFLARE_API_TOKEN
provider "cloudflare" {}

provider "sops" {}

provider "github" {
  owner = var.github_owner_slug
}
