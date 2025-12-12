variable "function_name" {type = string}
variable "dynamodb_table_name" {type = string}
variable "dynamodb_table_arn" {type = string}
variable "recaptcha_secret_key" {type = string; sensitive = true}
variable "lambda_source_dir" {type = string}
variable "environment" {type = string}
variable "tags" {type = map(string); default = {}}
