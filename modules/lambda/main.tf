module "ai_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.20"

  function_name = var.function_name
  handler       = "src.handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = var.timeout
  memory_size   = var.memory_size

  source_path = var.source_path
  python_cmd  = "python"

  environment_variables = {
    BEDROCK_EMBED_MODEL_ID = var.bedrock_embed_model_id
    # Nova Lite v1 is the ONLY on-demand text model permitted in us-east-1 under org SCP
    # p-rn6vr8ok. Nova 2 Lite needs a cross-region inference profile (us./global.) the SCP denies.
    BEDROCK_TEXT_MODEL_ID = var.bedrock_text_model_id
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
      resources = ["${var.reports_bucket_arn}/*"]
    }
  }

  tags = var.tags
}

# Allow S3 to invoke the function. Without this resource-based policy statement,
# S3 event notifications are silently dropped even with an IAM execution role.
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.ai_lambda.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.reports_bucket_id}"
}

resource "aws_s3_bucket_notification" "reports" {
  bucket = var.reports_bucket_id

  lambda_function {
    lambda_function_arn = module.ai_lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
