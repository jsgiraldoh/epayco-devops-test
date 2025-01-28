provider "aws" {
  region = var.aws_region
}

# Crear una cola SQS para almacenar las transacciones
resource "aws_sqs_queue" "transaction_queue" {
  name                      = "transaction-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

# Crear una función Lambda para procesar las transacciones
resource "aws_lambda_function" "process_transactions" {
  function_name = "process-transactions-${var.environment}"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "lambda_function_payload.zip"

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.transaction_queue.url
    }
  }
}

# Rol de IAM para Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Política para permitir que Lambda acceda a SQS
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda-sqs-policy-${var.environment}"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.transaction_queue.arn
      }
    ]
  })
}

# Mapeo de eventos SQS a Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.transaction_queue.arn
  function_name    = aws_lambda_function.process_transactions.arn
}

# Crear una API Gateway para recibir transacciones
resource "aws_api_gateway_rest_api" "transaction_api" {
  name        = "transaction-api-${var.environment}"
  description = "API para recibir transacciones"
}

resource "aws_api_gateway_resource" "transaction_resource" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "transactions"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transaction_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sqs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.transaction_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.transaction_queue.name}"
  credentials             = aws_iam_role.api_gateway_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

# Rol de IAM para API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "api-gateway-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Política para permitir que API Gateway envíe mensajes a SQS
resource "aws_iam_role_policy" "api_gateway_sqs_policy" {
  name = "api-gateway-sqs-policy-${var.environment}"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.transaction_queue.arn
      }
    ]
  })
}