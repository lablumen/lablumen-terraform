# Secrets Manager NAMESPACES — empty containers only (no aws_secretsmanager_secret_version).
# A human engineer populates values out-of-band (the single Infra↔App handshake). ESO reads
# secrets by name, never by value, so no secret material touches state or git.
resource "aws_secretsmanager_secret" "runtime" {
  for_each = var.runtime_secrets

  name        = each.key
  description = each.value

  recovery_window_in_days = var.secret_recovery_window_days

  tags = var.tags
}
