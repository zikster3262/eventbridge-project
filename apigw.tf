// Create HTTP API v2
resource "aws_apigatewayv2_api" "this" {
  name          = "api-gw"
  protocol_type = "HTTP"
  version       = "1.0"
}

// Create Cloudwatch Log group
resource "aws_cloudwatch_log_group" "api-logs" {
  name              = "/aws/api-gw/logs"
  retention_in_days = 30
  depends_on        = [aws_apigatewayv2_api.this]
}

// Create APIGW stage v1
resource "aws_apigatewayv2_stage" "api-gw" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "v1"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api-logs.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  depends_on = [aws_apigatewayv2_api.this]
}

output "name" {
  value = aws_apigatewayv2_api.this.api_endpoint
}
