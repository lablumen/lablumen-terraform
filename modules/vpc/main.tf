data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name            = "${var.name}-vpc"
  cidr            = var.cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Isolated DB tier — no NAT route, no IGW route.
  database_subnets                       = var.database_subnets
  create_database_subnet_group           = true
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = false

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags required by the AWS Load Balancer Controller and Karpenter subnet discovery.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.cluster_name
  }

  tags = var.tags
}

# ---- VPC Endpoint security group --------------------------------------------------
# Shared by all interface endpoints. Allows HTTPS from within the VPC only; pods and the
# ESO controller reach AWS APIs over PrivateLink without traversing the NAT GW.

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name}-vpc-endpoints-"
  description = "Allow HTTPS from within VPC to AWS PrivateLink interface endpoints."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ---- Gateway endpoint: S3 ---------------------------------------------------------
# Free; attaches to route tables (no ENIs). Routes S3 traffic from private subnets
# without hitting the NAT GW.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, { Name = "${var.name}-ep-s3" })
}

# ---- Interface endpoints ----------------------------------------------------------
# Placed in private app subnets. private_dns_enabled overrides public hostnames so AWS
# SDK calls resolve to the private ENI IP — no app changes needed.
# ssm + secretsmanager are required by ESO; ecr.api + ecr.dkr + logs by EKS nodes.

locals {
  interface_endpoints = {
    ssm             = "ssm"
    secretsmanager  = "secretsmanager"
    bedrock_runtime = "bedrock-runtime"
    textract        = "textract"
    ecr_api         = "ecr.api"
    ecr_dkr         = "ecr.dkr"
    logs            = "logs"
    sqs             = "sqs"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-${each.key}" })
}
