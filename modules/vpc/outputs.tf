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
  description = "Isolated DB-tier subnet IDs (no IGW/NAT route). Consumed by the rds module."
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

output "interface_endpoint_ids" {
  description = "Map of interface-endpoint key → VPC endpoint ID."
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.id }
}

output "endpoint_s3_id" {
  value = aws_vpc_endpoint.s3.id
}
