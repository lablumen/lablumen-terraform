data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  oidc_issuer = replace(var.cluster_oidc_issuer_url, "https://", "")
}

# ---- Cognito -----------------------------------------------------------------------

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

resource "aws_cognito_user_group" "roles" {
  for_each = toset(["PATIENT", "LAB_STAFF", "LAB_ADMIN"])

  name         = each.value
  user_pool_id = aws_cognito_user_pool.this.id
}

# ---- IRSA: ESO — cluster-level config-reader --------------------------------------
# Sole principal permitted to call secretsmanager:GetSecretValue on lablumen/app/*
# and ssm:GetParameter* on /lablumen/config/*. Per-service pods receive config from
# ESO-synced K8s Secrets (envFrom.secretRef) — they never call SM/SSM directly.

resource "aws_iam_role" "eso" {
  name = "${var.project}-eso"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eso" {
  name = "${var.project}-eso-access"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:*:secret:lablumen/app/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParametersByPath",
        ]
        Resource = "arn:aws:ssm:*:*:parameter/lablumen/config/*"
      },
    ]
  })
}

# ---- IRSA: report-service — S3 + Bedrock ------------------------------------------

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

  tags = var.tags
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

# ---- IRSA: notification-service — SQS + SES ---------------------------------------

module "notification_service_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.project}-notification-service"

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["lablumen:notification-service"]
    }
  }

  tags = var.tags
}

resource "aws_iam_policy" "notification_service" {
  name = "${var.project}-notification-service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = var.queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.ses_sender_email}"
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "notification_service" {
  role       = module.notification_service_irsa.iam_role_name
  policy_arn = aws_iam_policy.notification_service.arn
}

# ---- IRSA: ai-lambda — Textract + Bedrock + S3 ------------------------------------

module "ai_lambda_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.project}-ai-lambda"

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["lablumen:ai-lambda"]
    }
  }

  tags = var.tags
}

resource "aws_iam_policy" "ai_lambda" {
  name = "${var.project}-ai-lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["textract:DetectDocumentText", "textract:AnalyzeDocument"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${var.reports_bucket_arn}/*"
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ai_lambda" {
  role       = module.ai_lambda_irsa.iam_role_name
  policy_arn = aws_iam_policy.ai_lambda.arn
}
