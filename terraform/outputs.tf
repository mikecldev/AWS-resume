# ============================================================================
# Terraform Outputs
# ============================================================================

# ============================================================================
# S3 Outputs
# ============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = module.s3_frontend.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_frontend.bucket_arn
}

output "s3_bucket_website_endpoint" {
  description = "S3 bucket website endpoint"
  value       = module.s3_frontend.website_endpoint
}

# ============================================================================
# CloudFront Outputs
# ============================================================================

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_url" {
  description = "Full HTTPS URL of the CloudFront distribution"
  value       = "https://${module.cloudfront.cloudfront_domain_name}"
}

# ============================================================================
# DynamoDB Outputs
# ============================================================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

# ============================================================================
# Lambda Outputs
# ============================================================================

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.lambda.lambda_role_arn
}

# ============================================================================
# API Gateway Outputs
# ============================================================================

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.api_gateway.api_id
}

output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = module.api_gateway.api_url
}

output "api_gateway_invoke_url" {
  description = "Full invoke URL for the API Gateway"
  value       = module.api_gateway.invoke_url
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = module.api_gateway.stage_name
}

# ============================================================================
# Route 53 Outputs (if enabled)
# ============================================================================

output "route53_zone_id" {
  description = "ID of the Route 53 hosted zone (if custom domain enabled)"
  value       = var.enable_custom_domain ? module.route53[0].zone_id : null
}

output "route53_name_servers" {
  description = "Name servers for the Route 53 hosted zone (if custom domain enabled)"
  value       = var.enable_custom_domain ? module.route53[0].name_servers : null
}

# ============================================================================
# Website URL Output
# ============================================================================

output "website_url" {
  description = "The URL to access your cloud resume website"
  value = var.enable_custom_domain ? (
    "https://${var.domain_name}"
  ) : (
    "https://${module.cloudfront.cloudfront_domain_name}"
  )
}

# ============================================================================
# Deployment Instructions
# ============================================================================

output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = <<-EOT

  ========================================
  Cloud Resume - Deployment Instructions
  ========================================

  1. Upload Frontend Files to S3:
     aws s3 sync ../resume_front_end/ s3://${module.s3_frontend.bucket_id}/ --exclude ".DS_Store"

  2. Invalidate CloudFront Cache:
     aws cloudfront create-invalidation --distribution-id ${module.cloudfront.distribution_id} --paths "/*"

  3. Update Lambda Function:
     cd ../resume_back_end
     zip -r lambda_function.zip lambda_function.py
     aws lambda update-function-code --function-name ${module.lambda.lambda_name} --zip-file fileb://lambda_function.zip

  4. Test the API:
     curl -X POST ${module.api_gateway.api_url}/visit -H "Content-Type: application/json" -d '{"action":"visit"}'

  5. Access Your Website:
     ${var.enable_custom_domain ? "https://${var.domain_name}" : "https://${module.cloudfront.cloudfront_domain_name}"}

  ========================================
  Important URLs:
  ========================================

  Website:     ${var.enable_custom_domain ? "https://${var.domain_name}" : "https://${module.cloudfront.cloudfront_domain_name}"}
  API Gateway: ${module.api_gateway.api_url}
  S3 Bucket:   ${module.s3_frontend.bucket_id}

  ========================================
  Next Steps:
  ========================================

  1. Update app.js with API Gateway URL:
     - File: resume_front_end/app.js
     - Update: const API_BASE_URL = '${module.api_gateway.api_url}'

  2. Update reCAPTCHA site key:
     - File: resume_front_end/index.html (line 15)
     - File: resume_front_end/app.js (line 10)
     - Replace: YOUR_SITE_KEY with your actual key

  3. Monitor Lambda logs:
     aws logs tail /aws/lambda/${module.lambda.lambda_name} --follow

  EOT
}

# ============================================================================
# Configuration Summary
# ============================================================================

output "configuration_summary" {
  description = "Summary of the deployed configuration"
  value = {
    region              = var.aws_region
    environment         = var.environment
    custom_domain       = var.enable_custom_domain ? var.domain_name : "Not configured"
    s3_bucket           = module.s3_frontend.bucket_id
    lambda_function     = module.lambda.lambda_name
    dynamodb_table      = module.dynamodb.table_name
    api_gateway         = module.api_gateway.api_id
    cloudfront_distribution = module.cloudfront.distribution_id
    recaptcha_configured = length(var.recaptcha_secret_key) > 0
  }
}
