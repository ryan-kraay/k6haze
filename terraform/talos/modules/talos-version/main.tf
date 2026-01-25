##
## Version Validation
##

data "external" "talos_version_check" {
  program = ["bash", "${path.module}/scripts/lib.sh", "compare_versions",
    data.external.talos_version.result.version,
  var.talos_version == null ? data.external.talos_version.result.version : var.talos_version]
}

data "external" "k8s_version_check" {
  program = ["bash", "${path.module}/scripts/lib.sh", "compare_versions",
    data.external.k8s_version.result.version,
  var.k8s_version == null ? data.external.k8s_version.result.version : var.k8s_version]
}

##
## S3 State Management
##

data "external" "last_wipe_state" {
  # TODO expose var.s3_bucket
  program = ["bash", "${path.module}/scripts/lib.sh", "get_last_wipe_state", var.s3_path]
}

locals {
  current_talos_version = var.talos_version == null ? data.external.talos_version.result.version : var.talos_version
}

resource "aws_s3_object" "talos_wipe_state" {
  bucket = var.s3_bucket
  key    = var.s3_path
  content = jsonencode({
    last_wipe_at = (data.external.talos_version_check.result.comparison == "downgrade" || data.external.k8s_version_check.result.comparison == "downgrade") ? timestamp() : data.external.last_wipe_state.result.last_wipe_at
  })

  lifecycle {
    precondition {
      condition     = !(data.external.talos_version_check.result.comparison == "downgrade" && var.upgrade_policy == "no_wipe")
      error_message = "Talos downgrade detected but upgrade_policy is 'no_wipe'"
    }

    precondition {
      condition     = !(data.external.k8s_version_check.result.comparison == "downgrade" && var.upgrade_policy == "no_wipe")
      error_message = "K8s downgrade detected but upgrade_policy is 'no_wipe'"
    }
  }
}

##
## Talos
##

data "external" "talos_version" {
  program = ["bash", "${path.module}/scripts/lib.sh", "talos_version"]
}

resource "terraform_data" "desired_talos" {
  input = var.talos_version == null ? data.external.talos_version.result.version : var.talos_version

  provisioner "local-exec" {
    command = data.external.talos_version_check.result.comparison != "equal" ? "talosctl upgrade --image ghcr.io/siderolabs/installer:${self.input}" : "echo 'No Talos upgrade needed'"
  }
}

##
## K8s
##

data "external" "k8s_version" {
  program = ["bash", "${path.module}/scripts/lib.sh", "k8s_version"]
}

resource "terraform_data" "desired_k8s" {
  input = var.k8s_version == null ? data.external.k8s_version.result.version : var.k8s_version

  provisioner "local-exec" {
    command = data.external.k8s_version_check.result.comparison != "equal" ? "talosctl upgrade-k8s --to ${self.input}" : "echo 'No K8s upgrade needed'"
  }
}

##
## Wipe (only on downgrades)
##

resource "terraform_data" "wipe_filesystem" {

  provisioner "local-exec" {
    command = (data.external.talos_version_check.result.comparison == "downgrade" || data.external.k8s_version_check.result.comparison == "downgrade" || var.upgrade_policy == "force_wipe") ? "talosctl reset --system-labels-to-wipe EPHEMERAL --reboot --graceful=false" : "echo 'No wipe needed'"
  }

  # Force recreation when S3 state changes (only on downgrades)
  lifecycle {
    replace_triggered_by = [aws_s3_object.talos_wipe_state]
  }
}
