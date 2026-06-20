# Secrets Manager NAMESPACES.
# Empty containers only — no aws_secretsmanager_secret_version resources.
# A human engineer populates values out-of-band (the single Infra-App handshake).
# ESO reads secrets by name, never by value, so no secret material touches state or git.
resource "aws_secretsmanager_secret" "runtime" {
  for_each = var.runtime_secrets

  name        = each.key
  description = each.value

  recovery_window_in_days = var.secret_recovery_window_days

  tags = var.tags
}

# SSM Parameter Store — non-sensitive runtime config.
# Values are resolved module outputs (bucket IDs, queue URLs, Cognito pool IDs, static model names).
# All parameters are plain String; secrets never go here.
# ESO is granted ssm:GetParameter* on var.ssm_path_prefix/* only (see modules/identity eso policy).
resource "aws_ssm_parameter" "config" {
  for_each = var.ssm_config

  name      = "${var.ssm_path_prefix}/${each.key}"
  type      = "String"
  value     = each.value
  overwrite = true

  tags = var.tags
}
