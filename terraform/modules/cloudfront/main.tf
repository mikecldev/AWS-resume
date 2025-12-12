# ============================================================================
# CloudFront Module - CDN Distribution
# ============================================================================

# Origin Access Identity for S3
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.s3_bucket_id}"
}

# Bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloud Resume Distribution - ${var.environment}"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Aliases (custom domain)
  aliases = var.enable_custom_domain ? [var.domain_name] : []

  # Origin - S3 bucket
  origin {
    domain_name = var.s3_bucket_regional_domain
    origin_id   = "S3-${var.s3_bucket_id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id       = "S3-${var.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400  # 24 hours
    max_ttl     = 31536000  # 1 year
  }

  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # SSL/TLS certificate
  viewer_certificate {
    cloudfront_default_certificate = !var.enable_custom_domain
    acm_certificate_arn            = var.enable_custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "cloud-resume-distribution"
    }
  )
}
