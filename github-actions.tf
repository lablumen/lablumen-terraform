# GitHub Actions OIDC federation — allows the E2E workflow to assume AWS roles
# without storing long-lived static credentials as GitHub secrets.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # AWS validates GitHub's OIDC tokens via its own root CA trust since 2023;
  # this thumbprint is kept for API compliance but is not cryptographically verified.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

# ---- IAM role: lablumen-gh-actions -----------------------------------------------
# Assumed by GitHub Actions workflows in the lablumen org via OIDC (no static keys).
# Scope is limited to the lablumen/lablumen-terraform repo (where the E2E workflow lives).

resource "aws_iam_role" "github_actions" {
  name = "lablumen-gh-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Allow any trigger (push, workflow_dispatch, etc.) from the terraform repo
          "token.actions.githubusercontent.com:sub" = "repo:lablumen/lablumen-terraform:*"
        }
      }
    }]
  })

  tags = var.tags
}

# AdministratorAccess is appropriate here: this role provisions the entire platform
# (VPC, EKS, RDS, IAM, Secrets Manager, S3, ECR) via Terraform and must be able to
# create, modify, and destroy all of those resources.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
