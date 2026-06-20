module "notifications_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.2"

  name                       = var.queue_name
  visibility_timeout_seconds = 120

  tags = var.tags
}

resource "aws_sesv2_email_identity" "sender" {
  email_identity = var.ses_sender_email

  tags = var.tags
}
