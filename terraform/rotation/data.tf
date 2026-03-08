data "cloudflare_account" "this" {
  count = var.cloudflare_account_id == null ? 1 : 0
  filter = {
    name = ""
  }
}
locals {
  cloudflare_account_id = var.cloudflare_account_id == null ? data.cloudflare_account.this.0.id : var.cloudflare_account_id
}
