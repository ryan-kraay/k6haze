
# Due to limitation in lifecycle.replace_triggered_by -
#  Only resources, count.index, and each.key may be used in replace_triggered_by.
#  We MUST manually unroll these time_rotating slots.

# Furthermore, there is a bug with time_rotating and lifecycle policies
#  source: https://github.com/hashicorp/terraform-provider-time/issues/118
# The workaround is to create "time_static" as our proxy

locals {
  #
  # var.rotation_minutes is the stagger offset between alpha and beta. Both slots need a full rotation period of 2 * rotation_minutes so that each slot lives long enough to overlap with the other (to facilate credential migration during the rotation).
  #
  # Concretely: if rotation_minutes = 15, alpha rotates every 30 minutes, beta starts 15 minutes after alpha and also rotates every 30 minutes. This guarantees there's always one valid credential active — when alpha expires and rotates, beta still has 15 minutes left, and vice versa.
  #
  # Comment created by ChatGPT
  rotation_period = var.rotation_minutes * 2
}


resource "time_rotating" "_alpha" {
  rotation_minutes = local.rotation_period
}
resource "time_static" "alpha" {
  rfc3339 = time_rotating._alpha.rfc3339
}


resource "time_rotating" "_beta" {
  rotation_minutes = local.rotation_period

  # Stagger slot to overlap during rotation
  # TODO: negative timeadd() does not subtract (but TF docs says it should)
  #rfc3339 = timeadd(time_rotating._alpha.rotation_rfc3339, "-${var.rotation_minutes}m")
  rfc3339 = timeadd(time_rotating._alpha.rfc3339, "${var.rotation_minutes}m")

  lifecycle {
    # Avoid re-triggering after bootstrap MUST BE static
    ignore_changes = [rfc3339]
  }
}
resource "time_static" "beta" {
  rfc3339 = time_rotating._beta.rfc3339
}
