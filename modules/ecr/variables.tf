variable "repositories" {
  type        = list(string)
  description = "ECR repository names to create (e.g. 'lablumen/report-service'). Image naming is uniformly singular to match lablumen-k8s chart directories and lablumen-app CI path filters."
}

variable "keep_image_count" {
  type        = number
  default     = 20
  description = "Maximum number of images to retain per repository before the lifecycle policy expires older ones."

  validation {
    condition     = var.keep_image_count >= 1
    error_message = "keep_image_count must be at least 1 to avoid expiring all images."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
