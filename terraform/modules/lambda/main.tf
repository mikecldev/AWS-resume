# ============================================================================
# Lambda Module - Visitor Counter Function
# ============================================================================

# Package Lambda function
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${var.lambda_source_dir}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ]
        Resource = var.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime         = "python3.12"
  memory_size     = 256
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME  = var.dynamodb_table_name
      RECAPTCHA_SECRET_KEY = var.recaptcha_secret_key
    }
  }

  tags = merge(var.tags, {Name = var.function_name})
}
