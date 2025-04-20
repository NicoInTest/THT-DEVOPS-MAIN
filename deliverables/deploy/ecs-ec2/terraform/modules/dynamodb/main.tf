######################################################################################## 
# Add you Code Here to create a DynamoDB Tables for Orders and Inventory

resource "aws_dynamodb_table" "orders" {
  name           = "${var.environment}-orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "order_id"
  
  attribute {
    name = "order_id"
    type = "S"
  }

  tags = {
    Name        = "${var.environment}-orders"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "inventory" {
  name           = "${var.environment}-inventory"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "product_id"
  
  attribute {
    name = "product_id"
    type = "S"
  }

  tags = {
    Name        = "${var.environment}-inventory"
    Environment = var.environment
  }
}

# Initial data for inventory table
resource "aws_dynamodb_table_item" "inventory_item_1" {
  table_name = aws_dynamodb_table.inventory.name
  hash_key   = aws_dynamodb_table.inventory.hash_key

  item = <<ITEM
{
  "product_id": {"S": "PROD001"},
  "name": {"S": "Sample Product 1"},
  "price": {"N": "29"},
  "stock": {"N": "100"}
}
ITEM
}

resource "aws_dynamodb_table_item" "inventory_item_2" {
  table_name = aws_dynamodb_table.inventory.name
  hash_key   = aws_dynamodb_table.inventory.hash_key

  item = <<ITEM
{
  "product_id": {"S": "PROD002"},
  "name": {"S": "Sample Product 2"},
  "price": {"N": "49"},
  "stock": {"N": "50"}
}
ITEM
}
