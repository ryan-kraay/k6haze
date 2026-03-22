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

  default = ["development"]
}

variable "project_names" {
  description = "The names of the projects, which should match /terraform/<project_name>.  ie (talos, k8s, etc)"
  type        = list(string)
  nullable    = false
  default     = ["talos", "k8s"]
}

variable "recovery" {
  description = "The private age keys used to recover and rotate expired secrets"
  type        = map(map(string))
  nullable    = true
  default     = null
  sensitive   = true
}


variable "rotation_minutes" {
  description = "The period that keys should be rotated"
  # 43200 minutes == 30 days
  default = 43200
}
