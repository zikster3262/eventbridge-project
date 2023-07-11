// create iam policy document enabling to send eventbridge data to cloudwatch log group
data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_cloudwatch_event_rule.this.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_document = data.aws_iam_policy_document.this.json
  policy_name     = "cloudwatch-apgw-policy"
}

resource "aws_cloudwatch_event_rule" "this" {
  name           = "api-gw-event-rule-cw"
  event_bus_name = aws_cloudwatch_event_bus.this.name
  is_enabled     = true
  event_pattern = jsonencode({
    source = [
      "custom.aws.replayer"
    ]
  })

}

// Create cloudwatch log group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/events/eventbus-apigw"
  retention_in_days = 1
  depends_on        = [aws_cloudwatch_event_rule.this]
}

// Send messages to cloudwatch log group
resource "aws_cloudwatch_event_target" "this" {
  event_bus_name = aws_cloudwatch_event_bus.this.name
  rule           = aws_cloudwatch_event_rule.this.name
  arn            = aws_cloudwatch_log_group.this.arn
  depends_on     = [aws_cloudwatch_event_rule.this, aws_cloudwatch_log_group.this]
}
