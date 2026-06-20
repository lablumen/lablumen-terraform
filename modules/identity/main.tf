# ---- Cognito (raw resources; no official terraform-aws-modules equivalent) ----
resource "aws_cognito_user_pool" "this" {
  name                     = var.user_pool_name
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project}-web"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = false
  explicit_auth_flows                  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["http://localhost:5173/callback"]
  logout_urls                          = ["http://localhost:5173"]
}

# Roles are Cognito groups, surfaced in the JWT `cognito:groups` claim.
resource "aws_cognito_user_group" "roles" {
  for_each = toset(["PATIENT", "LAB_STAFF", "LAB_ADMIN"])

  name         = each.value
  user_pool_id = aws_cognito_user_pool.this.id
}

# ---- IRSA: representative role for report-service (S3 + Bedrock) ----
module "report_service_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.project}-report-service"

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["lablumen:report-service"]
    }
  }
}

resource "aws_iam_policy" "report_service" {
  name = "${var.project}-report-service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${var.reports_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "report_service" {
  role       = module.report_service_irsa.iam_role_name
  policy_arn = aws_iam_policy.report_service.arn
}
