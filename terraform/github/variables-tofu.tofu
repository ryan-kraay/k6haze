# Variables that are only present for OpenTofu

variable "terraform_statefile_passphrase" {
  description = "A passphrase used to encrypt/decrypt this statefile"
  sensitive   = true
}
