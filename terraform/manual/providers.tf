# https://opentofu.org/docs/language/state/encryption/


terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.17.0"
    }
  }
}

# Set CLOUDFLARE_API_TOKEN
provider "cloudflare" {}
