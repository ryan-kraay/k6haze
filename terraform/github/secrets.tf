
# Load our sops secrets from disk...
# WARNING:  unencrypted secrets are stored in our tfstate
#
# using `ephemeral sops_file` won't allow us to dynamically create
#  resources/secrets that use the env-var name.
data "sops_file" "env_secrets" {
  for_each    = fileset(path.root, "secrets/**/*.sops.env")
  source_file = each.value
}
# Storing secrets w/ newlines (ie: pem files) is hard to do with sops
#  see: https://github.com/getsops/sops/issues/965
# As an alternative we'll allow raw payloads to be encrypted
#  Unfortunately, we lose the ability to include useful things like
#  comments.
data "sops_file" "raw_secrets" {
  for_each    = fileset(path.root, "secrets/**/*.sops.raw")
  source_file = each.value

  input_type = "raw"
}

locals {
  # We will expand and flatten all the sops files into a single map
  # There will be no attempts to resolve duplicate secret keys
  environment_secrets = merge(
    # Process our *.sops.raw files...
    { for file_name, sops in data.sops_file.raw_secrets : "${split("/", file_name)[1]}#${split(".", basename(file_name))[0]}" => {
      # The format of file_name is: "secrets/<environment_name>/<secret_name>.sops.env"
      env_name = split("/", file_name)[1]

      # example: secrets/development/EXAMPLE.sops.raw
      #  basename: EXAMPLE.sops.raw
      #  split(".")[0]: EXAMPLE
      secret_name     = split(".", basename(file_name))[0]
      plaintext_value = sensitive(sops.raw)
    } },

    # Process our *.sops.env files...
    [for file_name, sops in data.sops_file.env_secrets : {
      # the sops-provider marks _all_ data as sensensitive, which means we cannot use
      # the map keys as part of our resource names.  So we'll mark the entire structure
      # as nonsensitive and remark the relevant bits
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

# Create the secret using our encrypted content
#  (thus stored in the tfstate as encrypted content)
resource "github_actions_secret" "encrypted_shared_secrets" {
  for_each = { for k, env_secret in local.environment_secrets : k => env_secret if env_secret.env_name == local.shared_environment_name }

  repository      = var.github_repo_name
  secret_name     = each.value.secret_name
  plaintext_value = each.value.plaintext_value
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
  plaintext_value = each.value.plaintext_value
}
