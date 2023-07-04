module "relayer" {
  source = "github.com/zikster3262/terraform-aws-modules/lambda"

  lambda_inputs = {
    name    = "apigw-relayer-eventbus"
    handler = "index.handler"
    runtime = "nodejs16.x"
  }

  archive_file_inputs = {
    archive_type     = "zip"
    source_dir       = "${path.module}/aws-lambda/relayer"
    output_path      = "${path.module}/aws-lambda/relayer/lambda.zip"
    output_file_mode = "0666"
  }

  environment_variables = {
    EVENTBUS    = aws_cloudwatch_event_bus.this.name
    MAX_RETRIES = 3
  }

}

resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  connection_type    = "INTERNET"
  integration_uri    = module.relayer.invoke_arn
  depends_on         = [module.relayer]
}

resource "aws_apigatewayv2_route" "this" {
  api_id     = aws_apigatewayv2_api.this.id
  route_key  = "POST /events"
  depends_on = [aws_apigatewayv2_api.this]
  target     = "integrations/${aws_apigatewayv2_integration.this.id}"
}


resource "aws_lambda_permission" "update_tem" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.relayer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
  depends_on    = [module.relayer]
}


