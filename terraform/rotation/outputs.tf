output "alpha_expiration" {
  description = "When the alpha tokens will expire"
  value       = time_rotating.alpha.rotation_rfc3339
}
output "beta_expiration" {
  description = "When the beta tokens will expire"
  value       = time_rotating.beta.rotation_rfc3339
}

output "beta_cloudflare_expiration" {
  description = "When the betak cloudflare tokens will expire"
  value       = { for k, v in cloudflare_account_token.beta : k => v.expires_on }
}
