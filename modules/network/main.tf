data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name            = "${var.name}-vpc"
  cidr            = var.cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Isolated DB tier — no NAT route, no IGW route. RDS lives here from P2 onward.
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
# Shared by all interface endpoints. Allows HTTPS from within the VPC only; pods and
# the ESO controller reach AWS APIs over PrivateLink without traversing the NAT GW.

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
# Gateway endpoints are free and attach to route tables rather than creating ENIs.
# Routes traffic to S3 from private subnets without hitting the NAT GW.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, { Name = "${var.name}-ep-s3" })
}

# ---- Interface endpoints ----------------------------------------------------------
# All placed in private app subnets (3 AZs = 3 ENIs per endpoint).
# private_dns_enabled = true overrides the public hostname so AWS SDK calls resolve
# to the private ENI IP inside the VPC — no DNS changes needed in application code.
#
# ssm + secretsmanager are required by ESO (P4) before ESO pods are deployed.
# ecr.api + ecr.dkr + logs are required by EKS nodes pulling images and emitting logs.

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-ssm" })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-secretsmanager" })
}

resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-bedrock-runtime" })
}

resource "aws_vpc_endpoint" "textract" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.textract"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-textract" })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-ecr-api" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-ecr-dkr" })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-logs" })
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.tags, { Name = "${var.name}-ep-sqs" })
}
