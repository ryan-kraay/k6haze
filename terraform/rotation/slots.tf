
# Due to limitation in lifecycle.replace_triggered_by -
#  Only resources, count.index, and each.key may be used in replace_triggered_by.
#  We MUST manually unroll these time_rotating slots.

# Furthermore, there is a bug with time_rotating and lifecycle policies
#  source: https://github.com/hashicorp/terraform-provider-time/issues/118
# The workaround is to create "time_static" as our proxy

resource "time_rotating" "_alpha" {
  rotation_minutes = var.rotation_minutes
}
resource "time_static" "alpha" {
  rfc3339 = time_rotating._alpha.rfc3339
}


resource "time_rotating" "_beta" {
  rotation_minutes = var.rotation_minutes

  # Stagger slot to overlap during rotation
  rfc3339 = timeadd(time_rotating._alpha.rotation_rfc3339, "-${floor(var.rotation_minutes / 2)}m")

  lifecycle {
    # Avoid re-triggering after bootstrap MUST BE static
    ignore_changes = [rfc3339]
  }
}
resource "time_static" "beta" {
  rfc3339 = time_rotating._beta.rfc3339
}
