output "lambda_arn" {value = aws_lambda_function.visitor_counter.arn}
output "lambda_name" {value = aws_lambda_function.visitor_counter.function_name}
output "lambda_role_arn" {value = aws_iam_role.lambda.arn}
output "lambda_invoke_arn" {value = aws_lambda_function.visitor_counter.invoke_arn}
