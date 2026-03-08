resource "customcrud" "age_keygen_alpha" {
  for_each = cloudflare_r2_bucket.tfstate

  hooks {
    create = "${path.module}/scripts/age-keygen.sh"
    read   = "${path.module}/scripts/recycle.sh"
    delete = "/usr/bin/true"
  }

  lifecycle {
    replace_triggered_by = [time_rotating.alpha]
  }
}

resource "customcrud" "age_keygen_beta" {
  for_each = toset(var.environment_names)

  hooks {
    create = "${path.module}/scripts/age-keygen.sh"
    read   = "${path.module}/scripts/recycle.sh"
    delete = "/usr/bin/true"
  }

  lifecycle {
    replace_triggered_by = [time_rotating.beta]
  }
}

locals {
  age_keygens = {
    alpha = customcrud.age_keygen_alpha
    beta  = customcrud.age_keygen_beta
  }
  # Choose the newest age_keygen
  age_keygen = timecmp(time_rotating.alpha.rotation_rfc3339, time_rotating.beta.rotation_rfc3339) > 1 ? customcrud.age_keygen_alpha : customcrud.age_keygen_beta
}
