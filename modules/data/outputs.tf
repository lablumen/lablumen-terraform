output "db_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "master_user_secret_arn" {
  value = module.rds.db_instance_master_user_secret_arn
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
