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

variable "s3_bucket" {
  description = "The S3 bucket to write our talos-wipe-state"
  nullable    = false
}

variable "s3_path" {
  description = "The name of the file in var.s3_bucket, which contains our talos-wipe-state"
  default     = "/talos-wipe-state.json"
  nullable    = false
}
