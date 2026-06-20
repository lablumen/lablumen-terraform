output "queue_url" {
  value = module.notifications_queue.queue_url
}

output "queue_arn" {
  value = module.notifications_queue.queue_arn
}

output "ses_sender_identity" {
  value = aws_sesv2_email_identity.sender.email_identity
}
