# source: https://developers.cloudflare.com/fundamentals/api/reference/permissions/
# source: https://developers.cloudflare.com/r2/api/tokens/#permissions
data "cloudflare_account_api_token_permission_groups_list" "r2" {
  for_each   = toset(["Workers R2 Storage Bucket Item Write"])
  scope      = "com.cloudflare.edge.r2.bucket"
  account_id = local.cloudflare_account_id
  name       = urlencode(each.key)
}

# TODO rename this to tfstates
resource "cloudflare_r2_bucket" "tfstate" {
  for_each   = toset(var.environment_names)
  account_id = local.cloudflare_account_id
  name       = "k6haze-${each.key}-tfstate"
  location   = "WEUR"
}

resource "cloudflare_account_token" "alpha" {
  for_each = cloudflare_r2_bucket.tfstate

  account_id = local.cloudflare_account_id
  name       = "${each.value.name} R/W ALPHA - ${formatdate("YYYYMMDD", time_rotating.alpha.rfc3339)}"

  policies = [{
    effect = "allow"
    permission_groups = [
      for k, v in data.cloudflare_account_api_token_permission_groups_list.r2 : { id = v.result[0].id }
    ]
    resources = jsonencode({
      "com.cloudflare.edge.r2.bucket.${local.cloudflare_account_id}_default_${each.value.name}" = "*"
    })
  }]

  expires_on = time_rotating.alpha.rotation_rfc3339

  lifecycle {
    replace_triggered_by = [time_rotating.alpha]
  }
}

resource "cloudflare_account_token" "beta" {
  for_each = cloudflare_r2_bucket.tfstate

  account_id = local.cloudflare_account_id
  name       = "${each.value.name} R/W BETA - ${formatdate("YYYYMMDD", time_rotating.beta.rfc3339)}"

  policies = [{
    effect = "allow"
    permission_groups = [
      for k, v in data.cloudflare_account_api_token_permission_groups_list.r2 : { id = v.result[0].id }
    ]
    resources = jsonencode({
      "com.cloudflare.edge.r2.bucket.${local.cloudflare_account_id}_default_${each.value.name}" = "*"
    })
  }]

  expires_on = time_rotating.beta.rotation_rfc3339

  lifecycle {
    replace_triggered_by = [time_rotating.beta]
  }
}

locals {
  # Choose the latest expiration
  cloudflare_account_token = timecmp(time_rotating.alpha.rotation_rfc3339, time_rotating.beta.rotation_rfc3339) > 1 ? cloudflare_account_token.alpha : cloudflare_account_token.beta
}

