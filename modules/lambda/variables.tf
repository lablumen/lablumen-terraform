variable "function_name" {
  type        = string
  description = "Lambda function name."
}

variable "source_path" {
  type        = string
  description = "Local filesystem path to the Lambda source directory. Packaged automatically by terraform-aws-modules/lambda."
}

variable "reports_bucket_id" {
  type        = string
  description = "S3 bucket ID (name) that triggers the Lambda on ObjectCreated events."
}

variable "reports_bucket_arn" {
  type        = string
  description = "S3 bucket ARN used in the IAM policy granting s3:GetObject to the Lambda execution role."
}

variable "bedrock_embed_model_id" {
  type        = string
  description = "Bedrock embedding model ID injected as BEDROCK_EMBED_MODEL_ID environment variable."
  default     = "amazon.titan-embed-text-v1"
}

variable "bedrock_text_model_id" {
  type        = string
  description = "Bedrock text generation model ID injected as BEDROCK_TEXT_MODEL_ID environment variable."
  default     = "amazon.nova-lite-v1:0"
}

variable "timeout" {
  type        = number
  description = "Lambda execution timeout in seconds."
  default     = 60
}

variable "memory_size" {
  type        = number
  description = "Lambda allocated memory in MB."
  default     = 512
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Logs retention for the Lambda log group."
  default     = 14
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
