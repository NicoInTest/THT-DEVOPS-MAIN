resource "aws_iam_role_policy" "order_api_dynamodb_policy" {
  name = "${var.environment}-order-api-dynamodb-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.orders_table_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "order_processor_dynamodb_policy" {
  name = "${var.environment}-order-processor-dynamodb-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.inventory_table_arn
        ]
      }
    ]
  })
}
