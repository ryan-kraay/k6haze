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

output "sops_public_keys" {
  description = "All the public keys for each project"
  # TODO: Fix the naming on this...
  value = {
    for proj in distinct(flatten([for env, projects in local.age_keygens : keys(projects)])) : proj => {
      for env, projects in local.age_keygens :
      env => projects[proj].output.public
      if contains(keys(projects), proj)
    }
  }
}


#output "sops_public_keys" {
#  value = { for k, v in local.age_keygens : k => v }
#  sensitive = true
#}
