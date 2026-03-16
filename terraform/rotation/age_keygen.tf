##
## Each bucket will have it's own AGE key
##
resource "customcrud" "age_keygen_alpha" {
  for_each = cloudflare_r2_bucket.tfstates

  hooks {
    create = "${path.module}/scripts/age-keygen.sh"
    read   = "${path.module}/scripts/recycle.sh"
    delete = "/usr/bin/true"
  }

  input = {
    # It appears that lifecycle replace_triggered_by is not working
    trigger = time_static.alpha.rfc3339
  }

  lifecycle {
    replace_triggered_by = [time_static.alpha]
  }
}

resource "customcrud" "age_keygen_beta" {
  for_each = cloudflare_r2_bucket.tfstates

  hooks {
    create = "${path.module}/scripts/age-keygen.sh"
    read   = "${path.module}/scripts/recycle.sh"
    delete = "/usr/bin/true"
  }

  input = {
    trigger = time_static.beta.rfc3339
  }

  lifecycle {
    replace_triggered_by = [time_static.beta]
  }
}

locals {
  age_keygens = {
    alpha = customcrud.age_keygen_alpha
    beta  = customcrud.age_keygen_beta
  }
  age_private_keys = {
    for proj in distinct(flatten([for env, projects in local.age_keygens : keys(projects)])) : proj => {
      for env, projects in local.age_keygens :
      env => projects[proj].output.private
      if contains(keys(projects), proj)
    }
  }
  # Choose the newest age_keygen
  latest_age_keygen = timecmp(time_rotating._alpha.rotation_rfc3339, time_rotating._beta.rotation_rfc3339) > 1 ? customcrud.age_keygen_alpha : customcrud.age_keygen_beta
}
