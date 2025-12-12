# ============================================================================
# DynamoDB Module - Visitor Data Storage
# ============================================================================

resource "aws_dynamodb_table" "visitors" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "visit_id"

  attribute {
    name = "visit_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {Name = var.table_name})
}
