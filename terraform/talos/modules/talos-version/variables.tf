variable "talos_version" {
  description = "Desired Talos version (null means accept current version)"
  type        = string
  default     = null
}

variable "k8s_version" {
  description = "Desired Kubernetes version (null means accept current version)"
  type        = string
  default     = null
}

variable "upgrade_policy" {
  description = "Upgrade policy: 'allow_downgrade', 'force_wipe', 'no_wipe'"
  type        = string
  default     = "no_wipe"

  validation {
    condition     = contains(["allow_downgrade", "force_wipe", "no_wipe"], var.upgrade_policy)
    error_message = "upgrade_policy must be one of: allow_downgrade, force_wipe, no_wipe"
  }
}

