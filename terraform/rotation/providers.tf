terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.18.0"
    }
    customcrud = {
      source  = "registry.terraform.io/customcrud/customcrud"
      version = "3.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}
