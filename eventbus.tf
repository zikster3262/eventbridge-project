// Create event bus
resource "aws_cloudwatch_event_bus" "this" {
  name = "apigw-eventbus"
}

