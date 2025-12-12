# ============================================================================
# Terraform Variables
# ============================================================================

# ============================================================================
# General Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-resume"
}

# ============================================================================
# Domain Configuration (Optional)
# ============================================================================

variable "enable_custom_domain" {
  description = "Enable custom domain for CloudFront"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain name (e.g., example.com or www.example.com)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate in us-east-1 for CloudFront (required if using custom domain)"
  type        = string
  default     = ""
}

# ============================================================================
# reCAPTCHA Configuration
# ============================================================================

variable "recaptcha_secret_key" {
  description = "Google reCAPTCHA v3 secret key"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.recaptcha_secret_key) > 0
    error_message = "reCAPTCHA secret key must be provided."
  }
}

variable "recaptcha_score_threshold" {
  description = "Minimum reCAPTCHA score to consider valid (0.0 to 1.0)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.recaptcha_score_threshold >= 0.0 && var.recaptcha_score_threshold <= 1.0
    error_message = "reCAPTCHA score threshold must be between 0.0 and 1.0."
  }
}

# ============================================================================
# Lambda Configuration
# ============================================================================

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

# ============================================================================
# DynamoDB Configuration
# ============================================================================

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.dynamodb_billing_mode)
    error_message = "DynamoDB billing mode must be PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "enable_dynamodb_pitr" {
  description = "Enable DynamoDB Point-in-Time Recovery"
  type        = bool
  default     = true
}

# ============================================================================
# CloudFront Configuration
# ============================================================================

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "cloudfront_default_ttl" {
  description = "CloudFront default cache TTL in seconds"
  type        = number
  default     = 86400 # 24 hours
}

variable "cloudfront_max_ttl" {
  description = "CloudFront maximum cache TTL in seconds"
  type        = number
  default     = 31536000 # 1 year
}

variable "cloudfront_min_ttl" {
  description = "CloudFront minimum cache TTL in seconds"
  type        = number
  default     = 0
}

# ============================================================================
# API Gateway Configuration
# ============================================================================

variable "api_gateway_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "api_gateway_throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 10000
}

# ============================================================================
# Logging Configuration
# ============================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "enable_api_gateway_logging" {
  description = "Enable API Gateway access logging"
  type        = bool
  default     = true
}

# ============================================================================
# Tags
# ============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
