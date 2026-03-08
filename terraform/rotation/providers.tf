terraform {
  required_providers {
    customcrud = {
      source  = "registry.terraform.io/customcrud/customcrud"
      version = "3.11.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.18.0"
    }
  }
}
