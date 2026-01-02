output "buckets" {
  description = "The buckets created"
  value = {
    for k, v in cloudflare_r2_bucket.tfstates : k => v.name
  }
}

output "cloudflare_account_id" {
  description = "The unique account id"
  value       = local.account_id
}
