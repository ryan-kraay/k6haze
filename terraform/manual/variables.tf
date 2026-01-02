variable "account_id" {
  description = "The Cloudflare Account to apply our changes too."
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
}
