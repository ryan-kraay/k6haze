data "cloudflare_account" "this" {
  count = var.account_id == null ? 1 : 0
  filter = {
    name = ""
  }
}

locals {
  account_id = var.account_id == null ? data.cloudflare_account.this.0.id : var.account_id
}

resource "cloudflare_r2_bucket" "tfstates" {
  for_each = toset(var.environment_names)

  account_id = local.account_id
  name       = "k6haze-${each.value}-tfstate"
  location   = "WEUR"
}
