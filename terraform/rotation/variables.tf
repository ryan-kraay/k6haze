variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  nullable    = true
  default     = null
}

variable "environment_names" {
  description = "Apply our changes to a specific domain/environment (re: development, staging, production, etc)"
  type        = list(string)

  validation {
    condition     = length(var.environment_names) > 0
    error_message = "The list must not be empty."
  }

  validation {
    condition     = alltrue([for s in var.environment_names : s != ""])
    error_message = "The list must not contain empty strings."
  }

  default = ["production"]
}

variable "project_names" {
  description = "The names of the projects, which should match /terraform/<project_name>.  ie (talos, k8s, etc)"
  type        = list(string)
  nullable    = false
  default     = ["talos"]
}

variable "rotation_minutes" {
  description = "The period that keys should be rotated"
  default     = 10
}
