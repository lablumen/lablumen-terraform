variable "runtime_secrets" {
  type        = map(string)
  description = "Map of Secrets Manager secret name → description. Terraform creates empty containers only; values are hand-populated out-of-band."
}

variable "secret_recovery_window_days" {
  type        = number
  default     = 7
  description = "Recovery window in days before a deleted secret is permanently purged. Use 0 only in non-production."

  validation {
    condition     = var.secret_recovery_window_days == 0 || var.secret_recovery_window_days >= 7
    error_message = "secret_recovery_window_days must be 0 (immediate, non-prod only) or between 7 and 30."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
