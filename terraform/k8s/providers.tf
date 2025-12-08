terraform {
  # source: https://developers.cloudflare.com/terraform/advanced-topics/remote-backend/
  backend "s3" {
    bucket                      = var.terraform_statefile_bucket
    key                         = "k8s.tfstate"
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.0"
    }
  }
}

provider "kubernetes" {
}
