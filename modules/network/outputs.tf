output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "database_subnets" {
  description = "Isolated DB-tier subnet IDs (no IGW/NAT route). Consumed by module.data in P2."
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "RDS subnet group name created for the isolated DB tier."
  value       = module.vpc.database_subnet_group_name
}

output "vpc_endpoint_sg_id" {
  description = "Security group shared by all VPC interface endpoints (ingress 443 from VPC CIDR)."
  value       = aws_security_group.vpc_endpoints.id
}

output "endpoint_s3_id" {
  value = aws_vpc_endpoint.s3.id
}

output "endpoint_ssm_id" {
  value = aws_vpc_endpoint.ssm.id
}

output "endpoint_secretsmanager_id" {
  value = aws_vpc_endpoint.secretsmanager.id
}

output "endpoint_bedrock_runtime_id" {
  value = aws_vpc_endpoint.bedrock_runtime.id
}

output "endpoint_textract_id" {
  value = aws_vpc_endpoint.textract.id
}

output "endpoint_ecr_api_id" {
  value = aws_vpc_endpoint.ecr_api.id
}

output "endpoint_ecr_dkr_id" {
  value = aws_vpc_endpoint.ecr_dkr.id
}

output "endpoint_logs_id" {
  value = aws_vpc_endpoint.logs.id
}

output "endpoint_sqs_id" {
  value = aws_vpc_endpoint.sqs.id
}
