variable "project" {
  type        = string
  description = "Project name prefix used for naming the Cognito user pool client."
}

variable "user_pool_name" {
  type        = string
  description = "Display name for the Cognito user pool."
}

variable "callback_urls" {
  type        = list(string)
  description = "Allowed OAuth callback (redirect) URLs for the SPA web client."
  default     = ["http://localhost:5173/callback"]
}

variable "logout_urls" {
  type        = list(string)
  description = "Allowed OAuth logout URLs for the SPA web client."
  default     = ["http://localhost:5173"]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
