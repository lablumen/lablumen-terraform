module "notifications_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.2"

  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds

  tags = var.tags
}
