locals {
  oidc_issuer    = replace(var.cluster_oidc_issuer_url, "https://", "")
  repo_terraform = "repo:${var.github_org}/${var.terraform_repo}"
  # OIDC `sub` allow-lists for the per-service repos (polyrepo).
  app_service_subs = [for r in var.app_service_repos : "repo:${var.github_org}/${r}:*"]
  frontend_sub     = "repo:${var.github_org}/${var.frontend_repo}:*"
  state_bucket_arn = "arn:aws:s3:::${var.state_bucket_name}"
}

# ===================================================================================
# GitHub Actions OIDC federation (no static credentials anywhere)
# ===================================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates GitHub OIDC tokens against its own root CA trust; thumbprint kept for API
  # compliance but not cryptographically verified.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

# ---- Role: terraform PLAN (read-only, runs on PR + push to main) -------------------
resource "aws_iam_role" "tf_plan" {
  name = "${var.project}-tf-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "${local.repo_terraform}:pull_request",
            "${local.repo_terraform}:ref:refs/heads/main",
          ]
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "tf_plan_readonly" {
  role       = aws_iam_role.tf_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# State access for plan (read/write state + the S3-native lock file).
resource "aws_iam_role_policy" "tf_plan_state" {
  name = "${var.project}-tf-plan-state"
  role = aws_iam_role.tf_plan.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.state_bucket_arn },
      # GetObject/PutObject for state; DeleteObject releases the S3-native lock file.
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = "${local.state_bucket_arn}/*" },
    ]
  })
}

# ---- Role: terraform APPLY (admin, gated by GitHub Environment 'production') --------
resource "aws_iam_role" "tf_apply" {
  name = "${var.project}-tf-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # The apply job runs in the GitHub Environment 'production' (required-reviewer approval gate).
          "token.actions.githubusercontent.com:sub" = "${local.repo_terraform}:environment:production"
        }
      }
    }]
  })

  tags = var.tags
}

# AdministratorAccess: this role provisions/destroys the entire platform.
resource "aws_iam_role_policy_attachment" "tf_apply_admin" {
  role       = aws_iam_role.tf_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---- Role: app CI → push images to ECR --------------------------------------------
resource "aws_iam_role" "app_ci_ecr" {
  name = "${var.project}-app-ci-ecr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.app_service_subs }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "app_ci_ecr" {
  name = "${var.project}-app-ci-ecr"
  role = aws_iam_role.app_ci_ecr.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
        ]
        Resource = var.backend_ecr_repository_arns
      },
    ]
  })
}

# ---- Role: frontend build → push image to ECR (frontend repo only) -----------------
resource "aws_iam_role" "frontend_build" {
  name = "${var.project}-frontend-build"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.frontend_sub }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "frontend_build" {
  name = "${var.project}-frontend-build"
  role = aws_iam_role.frontend_build.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
        ]
        Resource = var.frontend_ecr_repository_arn
      },
    ]
  })
}

# ===================================================================================
# IRSA roles (workload identity for in-cluster controllers + services)
# ===================================================================================

# ---- ESO — cluster config reader (SM lablumen/app/* + SSM /lablumen/config/*) -------
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
          "${local.oidc_issuer}:sub" = "system:serviceaccount:external-secrets:${var.eso_service_account_name}"
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
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = "arn:aws:secretsmanager:*:*:secret:lablumen/app/*" },
      { Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"], Resource = "arn:aws:ssm:*:*:parameter/lablumen/config/*" },
      # ESO dataFrom find-by-name discovers params via DescribeParameters, which IAM only allows on "*"
      # (no resource-level scoping). Values are still readable only under /lablumen/config/* above.
      { Effect = "Allow", Action = ["ssm:DescribeParameters"], Resource = "*" },
    ]
  })
}

# ---- report-service — S3 + Bedrock (trusts prod AND dev namespaces) -----------------
module "report_service_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.project}-report-service"
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["lablumen:report-service", "lablumen-dev:report-service"]
    }
  }
  tags = var.tags
}

resource "aws_iam_policy" "report_service" {
  name = "${var.project}-report-service"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject"], Resource = "${var.reports_bucket_arn}/*" },
      { Effect = "Allow", Action = ["bedrock:InvokeModel"], Resource = "*" },
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "report_service" {
  role       = module.report_service_irsa.iam_role_name
  policy_arn = aws_iam_policy.report_service.arn
}

# ---- notification-service — SQS + SES (trusts prod AND dev namespaces) --------------
module "notification_service_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.project}-notification-service"
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["lablumen:notification-service", "lablumen-dev:notification-service"]
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
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = var.queue_arn
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = var.ses_identity_arn
      },
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "notification_service" {
  role       = module.notification_service_irsa.iam_role_name
  policy_arn = aws_iam_policy.notification_service.arn
}

# ---- AWS Load Balancer Controller --------------------------------------------------
module "lbc_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name                              = "${var.project}-lbc"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
  tags = var.tags
}

# ---- external-dns — manages Route53 records in the app's hosted zone ----------------
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name                     = "${var.project}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [var.route53_zone_arn]
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
  tags = var.tags
}

# ---- ai-lambda — Textract + Bedrock + S3 (IRSA kept for parity with the workload) ---
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
      { Effect = "Allow", Action = ["textract:DetectDocumentText", "textract:AnalyzeDocument"], Resource = "*" },
      { Effect = "Allow", Action = ["bedrock:InvokeModel"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject"], Resource = "${var.reports_bucket_arn}/*" },
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ai_lambda" {
  role       = module.ai_lambda_irsa.iam_role_name
  policy_arn = aws_iam_policy.ai_lambda.arn
}
