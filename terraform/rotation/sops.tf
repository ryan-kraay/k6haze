resource "local_file" "sops_yaml" {
  for_each = local.projects

  filename = "${path.module}/../${each.value.project_name}/secrets/${each.value.environment_name}/.sops.yaml"
  content  = <<-EOT
    creation_rules:
      - path_regex: ".sops(.env|.raw)$"
        age: ${local.latest_age_keygen[each.key].output.public}
  EOT

  directory_permission = "0755"
  file_permission      = "0644"
}

locals {
  last_decryption_secrets = var.recovery != null ? var.recovery : local.age_private_keys
}

resource "terraform_data" "reencrypt_secrets" {
  for_each = local.projects

  triggers_replace = [
    local.latest_age_keygen[each.key].output.public
  ]

  provisioner "local-exec" {
    # The find-command allows us to gracefully skip, if there are no '*.sops.*' in our destination folder
    command = "cd ${path.module}/../${each.value.project_name}/secrets/${each.value.environment_name} && find . -maxdepth 1 -name '*.sops.*' ! -name '.sops.yaml' | xargs -r sops updatekeys -y"

    environment = {
      SOPS_AGE_KEY = sensitive(join("\n", values(local.last_decryption_secrets[each.key])))
    }
  }

  depends_on = [local_file.sops_yaml]
}

resource "customcrud" "tfstate_secrets" {
  for_each = local.projects

  input = {
    path = "${path.module}/../${each.value.project_name}/secrets/${each.value.environment_name}/tfstate.sops.env"
    content = sensitive(<<EOL
AWS_ACCESS_KEY_ID_=${local.latest_account_token[each.key].id}
AWS_SECRET_ACCESS_KEY=${sensitive(sha256(local.latest_account_token[each.key].value))}
TF_VAR_terraform_statefile_bucket=${cloudflare_r2_bucket.tfstates[each.key].name}
TF_VAR_terraform_statefile_passphrase=foooo
TF_VAR_cloudflare_account_id=${cloudflare_r2_bucket.tfstates[each.key].account_id}
EOL
    )
    type    = "dotenv" #json, yaml, dotenv, and binary
    age_key = local.latest_age_keygen[each.key].output.public
  }

  hooks {
    create = "${path.module}/scripts/sops.sh"
    read   = "${path.module}/scripts/recycle.sh"
    delete = "rm -f ${path.module}/../${each.value.project_name}/secrets/${each.value.environment_name}/tfstate.sops.env"
  }

  # we want to encrypt all our existing secrets
  depends_on = [terraform_data.reencrypt_secrets]
}

resource "local_file" "age_key" {
  for_each = local.projects

  filename = "${path.module}/../${each.value.project_name}/secrets/${each.value.environment_name}/age.key"
  content = sensitive(join("\n", [
    for slot in values(local.age_keygens) : slot[each.key].output.private
  ]))

  directory_permission = "0755"
  file_permission      = "0644"

  # Once all our secrets have been encrypted with the latest key
  depends_on = [customcrud.tfstate_secrets]
}

