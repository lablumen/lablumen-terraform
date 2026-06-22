variable "queue_name" {
  type        = string
  description = "SQS queue name for the notifications queue (notification-service send/receive)."
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Message visibility timeout. Should exceed the consumer's max processing time."
  default     = 120
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
