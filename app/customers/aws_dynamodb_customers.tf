resource "aws_dynamodb_table" "customers" {
  name         = "${var.project}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "document_number"
    type = "S"
  }

  global_secondary_index {
    name            = "document_number_gsi"
    hash_key        = "document_number"
    projection_type = "ALL"
  }
}
