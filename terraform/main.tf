# ============================================================================
# Cloud Resume Challenge - Main Terraform Configuration
# ============================================================================
# This creates a complete serverless architecture for a cloud resume with:
# - S3 static website hosting
# - CloudFront CDN distribution
# - API Gateway REST API
# - Lambda function for visitor counter
# - DynamoDB for storing visitor data
# - Route 53 DNS (optional)
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Optional: Configure S3 backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cloud-resume/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CloudResumeChallenge"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Owner       = var.project_name
    }
  }
}

# Provider for us-east-1 (required for CloudFront ACM certificate)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "CloudResumeChallenge"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Resource naming
  s3_bucket_name       = "${var.project_name}-frontend-${var.environment}"
  lambda_function_name = "${var.project_name}-visitor-counter-${var.environment}"
  dynamodb_table_name  = "${var.project_name}-visitors-${var.environment}"
  api_gateway_name     = "${var.project_name}-api-${var.environment}"

  # Tags
  common_tags = {
    Project     = "CloudResumeChallenge"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# S3 Bucket for Frontend (Static Website)
# ============================================================================

module "s3_frontend" {
  source = "./modules/s3"

  bucket_name = local.s3_bucket_name
  environment = var.environment
  tags        = local.common_tags
}

# ============================================================================
# CloudFront Distribution
# ============================================================================

module "cloudfront" {
  source = "./modules/cloudfront"

  s3_bucket_id                = module.s3_frontend.bucket_id
  s3_bucket_regional_domain   = module.s3_frontend.bucket_regional_domain_name
  s3_bucket_arn               = module.s3_frontend.bucket_arn
  domain_name                 = var.domain_name
  enable_custom_domain        = var.enable_custom_domain
  acm_certificate_arn         = var.acm_certificate_arn
  environment                 = var.environment
  tags                        = local.common_tags
}

# ============================================================================
# DynamoDB Table for Visitor Data
# ============================================================================

module "dynamodb" {
  source = "./modules/dynamodb"

  table_name  = local.dynamodb_table_name
  environment = var.environment
  tags        = local.common_tags
}

# ============================================================================
# Lambda Function for Visitor Counter
# ============================================================================

module "lambda" {
  source = "./modules/lambda"

  function_name         = local.lambda_function_name
  dynamodb_table_name   = module.dynamodb.table_name
  dynamodb_table_arn    = module.dynamodb.table_arn
  recaptcha_secret_key  = var.recaptcha_secret_key
  lambda_source_dir     = "${path.root}/../resume_back_end"
  environment           = var.environment
  tags                  = local.common_tags
}

# ============================================================================
# API Gateway REST API
# ============================================================================

module "api_gateway" {
  source = "./modules/api_gateway"

  api_name            = local.api_gateway_name
  lambda_function_arn = module.lambda.lambda_arn
  lambda_function_name = module.lambda.lambda_name
  environment         = var.environment
  tags                = local.common_tags
}

# ============================================================================
# Route 53 DNS (Optional)
# ============================================================================

module "route53" {
  source = "./modules/route53"
  count  = var.enable_custom_domain ? 1 : 0

  domain_name               = var.domain_name
  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  tags                      = local.common_tags
}

# ============================================================================
# CloudWatch Log Groups
# ============================================================================

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-lambda-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${local.api_gateway_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-api-logs"
    }
  )
}
