# SSM Parameter Store — non-sensitive runtime config (bucket IDs, queue URLs, Cognito IDs, model
# names). All plain String; secrets never go here. ESO is granted ssm:GetParameter* on
# var.path_prefix/* only.
resource "aws_ssm_parameter" "config" {
  for_each = var.config

  name      = "${var.path_prefix}/${each.key}"
  type      = "String"
  value     = each.value
  overwrite = true

  tags = var.tags
}
