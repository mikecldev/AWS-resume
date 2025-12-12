variable "s3_bucket_id" {type = string}
variable "s3_bucket_regional_domain" {type = string}
variable "s3_bucket_arn" {type = string}
variable "domain_name" {type = string; default = ""}
variable "enable_custom_domain" {type = bool; default = false}
variable "acm_certificate_arn" {type = string; default = ""}
variable "environment" {type = string}
variable "tags" {type = map(string); default = {}}
