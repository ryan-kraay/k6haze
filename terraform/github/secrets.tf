
# Load our sops secrets from disk...
# WARNING:  unencrypted secrets are stored in our tfstate
#
# using `ephemeral sops_file` won't allow us to dynamically create
#  resources/secrets that use the env-var name.
data "sops_file" "secrets" {
  for_each    = fileset(path.root, "secrets/**/*.sops.env")
  source_file = each.value
}

locals {
  # We will expand and flatten all the sops files into a single map
  # There will be no attempts to resolve duplicate secret keys
  environment_secrets = merge([for file_name, sops in data.sops_file.secrets : {
    for k, v in nonsensitive(sops.data) : "${split("/", file_name)[1]}#${k}" => {
      # The format of file_name is: "secrets/<environment_name>/<meaningless_name>.sops.env"
      env_name = split("/", file_name)[1]

      secret_name     = k
      plaintext_value = sensitive(v)
    }
  }]...)

  #
  # github secrets allows secrets to be encapsulated in an environment, but also
  # allows secrets to be shared between *all* environments.
  #
  # inorder to allow the sharing of secrets between all environments, we will reserve a path in our `secrets/` folder
  #
  shared_environment_name = "shared"
}


# Fetch the public github action key
data "github_actions_public_key" "gha_public_key" {
  repository = var.github_repo_name
}

# Encrypt our plain-text content with the gha-public-key
#  WARNING:  We're trusting some unsigned random provider
#    to encrypt our data.  I wouldn't use this in production, unless
#    it was insourced and audited.
# 
# See: https://github.com/integrations/terraform-provider-github/issues/888
data "sodium_encrypted_item" "secrets" {
  for_each = { for k, env_secret in local.environment_secrets : k => env_secret.plaintext_value }

  public_key_base64 = data.github_actions_public_key.gha_public_key.key
  content_base64    = base64encode(each.value)
}

# Create the secret using our encrypted content
#  (thus stored in the tfstate as encrypted content)
resource "github_actions_secret" "encrypted_shared_secrets" {
  for_each = { for k, env_secret in local.environment_secrets : k => env_secret if env_secret.env_name == local.shared_environment_name }

  repository      = var.github_repo_name
  secret_name     = each.value.secret_name
  encrypted_value = data.sodium_encrypted_item.secrets[each.key].encrypted_value_base64
}

resource "github_repository_environment" "environments" {
  for_each = toset([for env_secret in values(local.environment_secrets) : env_secret.env_name if env_secret.env_name != local.shared_environment_name])

  environment = each.value
  repository  = var.github_repo_name
}

resource "github_actions_environment_secret" "encrypted_secrets" {
  for_each = { for k, env_secret in local.environment_secrets : k => env_secret if env_secret.env_name != local.shared_environment_name }

  repository  = var.github_repo_name
  environment = github_repository_environment.environments[each.value.env_name].environment

  secret_name     = each.value.secret_name
  encrypted_value = data.sodium_encrypted_item.secrets[each.key].encrypted_value_base64
}
