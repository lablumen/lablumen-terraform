variable "queue_name" {
  type        = string
  description = "SQS queue name for the notifications queue. Used by notification-service to send and receive email trigger messages."
}

variable "ses_sender_email" {
  type        = string
  description = "Email address to register as a verified SES v2 sending identity. Must be verified before SES will send from it."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
