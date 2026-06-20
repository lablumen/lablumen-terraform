module "reports_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = var.reports_bucket_name
  force_destroy = true

  # Private PHI store — no public access, encrypted at rest.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = var.tags
}

module "ai_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.20"

  function_name = var.lambda_function_name
  handler       = "src.handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 512

  source_path = var.lambda_source_path

  environment_variables = {
    BEDROCK_EMBED_MODEL_ID = "amazon.titan-embed-text-v1"
    BEDROCK_TEXT_MODEL_ID  = "amazon.nova-2-lite-v1:0"
    # DATABASE_URL is injected from Secrets Manager at deploy time.
  }

  attach_policy_statements = true
  policy_statements = {
    textract = {
      effect    = "Allow"
      actions   = ["textract:DetectDocumentText", "textract:AnalyzeDocument"]
      resources = ["*"]
    }
    bedrock = {
      effect    = "Allow"
      actions   = ["bedrock:InvokeModel"]
      resources = ["*"]
    }
    s3_read = {
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.reports_bucket.s3_bucket_arn}/*"]
    }
  }

  tags = var.tags
}

# S3 -> Lambda notification (Terraform-managed path; the SAM template wires this for standalone use).
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.ai_lambda.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.reports_bucket.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "reports" {
  bucket = module.reports_bucket.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.ai_lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
