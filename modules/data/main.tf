resource "aws_security_group" "rds" {
  name_prefix = "${var.identifier}-rds-"
  description = "Allow Postgres from within the VPC (EKS nodes / Lambda ENIs)."
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.9"

  identifier = var.identifier

  engine               = "postgres"
  engine_version       = var.engine_version
  family               = var.family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  port     = 5432

  # Credentials managed by Secrets Manager (no password in state).
  manage_master_user_password = true

  multi_az               = false
  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  tags = var.tags
}
