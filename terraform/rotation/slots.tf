
# Due to limitation in lifecycle.replace_triggered_by -
#  Only resources, count.index, and each.key may be used in replace_triggered_by.
#  We MUST manually unroll these time_rotating slots.

resource "time_rotating" "alpha" {
  rotation_minutes = var.rotation_minutes
}

resource "time_rotating" "beta" {
  rotation_minutes = var.rotation_minutes

  # Stagger slot to overlap during rotation
  rfc3339 = timeadd(time_rotating.alpha.rotation_rfc3339, "-${floor(var.rotation_minutes / 2)}m")

  lifecycle {
    # Avoid re-triggering after bootstrap MUST BE static
    ignore_changes = [rfc3339]
  }
}
