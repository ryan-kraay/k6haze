resource "github_repository_environment" "environments" {
  for_each = toset(keys(local.github_projects))

  environment = each.value
  repository  = var.github_repo_name
  lifecycle {
    # used by terraform/github
    prevent_destroy = true
  }
}

resource "github_actions_environment_secret" "age_keys" {
  for_each = github_repository_environment.environments

  repository  = var.github_repo_name
  environment = each.value.environment

  secret_name = "SOPS_AGE_KEY"
  plaintext_value = sensitive(join("\n", flatten([
    # We're exploiting the fact that alpha and beta have _identical_ keys
    # We include _both_ the alpha and beta keys, so existing branches will
    # continue to work, until the age keys have naturally been cycled out
    for age_key in keys(customcrud.age_keygen_alpha) :
    startswith(age_key, each.key) ? [
      "# ALPHA ${age_key}",
      "# ${customcrud.age_keygen_alpha[age_key].output.public}",
      customcrud.age_keygen_alpha[age_key].output.private,
      "# BETA ${age_key}",
      "# ${customcrud.age_keygen_beta[age_key].output.public}",
      customcrud.age_keygen_beta[age_key].output.private,
    ] : []
  ])))
}
