# SES domain identity with Easy DKIM. SES generates 3 CNAME tokens; publishing them in Route53
# auto-verifies the domain (no mailbox needed). Once verified, ANY address @domain can send.
resource "aws_sesv2_email_identity" "sender" {
  email_identity = var.domain_name

  tags = var.tags
}

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.route53_zone_id
  name    = "${aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}
