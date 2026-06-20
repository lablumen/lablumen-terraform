terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state is intentionally on hold (single centralized tfvars for now). When enabling:
  # backend "s3" {
  #   bucket         = "lablumen-tfstate"
  #   key            = "global/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "lablumen-tflock"
  #   encrypt        = true
  # }
}
