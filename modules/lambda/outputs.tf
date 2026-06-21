output "lambda_function_arn" {
  description = "ARN of the AI processing Lambda function."
  value       = module.ai_lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the AI processing Lambda function."
  value       = module.ai_lambda.lambda_function_name
}
