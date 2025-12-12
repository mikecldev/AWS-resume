output "api_id" {value = aws_api_gateway_rest_api.api.id}
output "api_url" {value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"}
output "invoke_url" {value = aws_api_gateway_stage.prod.invoke_url}
output "stage_name" {value = aws_api_gateway_stage.prod.stage_name}

data "aws_region" "current" {}
