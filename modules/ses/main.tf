resource "aws_sesv2_email_identity" "sender" {
  email_identity = var.ses_sender_email

  tags = var.tags
}
