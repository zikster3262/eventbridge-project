# # Create an SQS queue
# resource "aws_sqs_queue" "sqs" {
#   name = "apigw-create"
# }

# # Create an EventBridge rule
# resource "aws_cloudwatch_event_rule" "sqs" {
#   name           = "api-gw-event-rule-sqs"
#   description    = "EventBridge rule for sending events to SQS"
#   event_bus_name = aws_cloudwatch_event_bus.this.name
#   is_enabled     = true
#   event_pattern = jsonencode({
#     source = [
#       "custom.aws.replayer"
#     ]
#   })
# }

# # Create an EventBridge target to send events to SQS
# resource "aws_cloudwatch_event_target" "sqs" {
#   rule           = aws_cloudwatch_event_rule.sqs.name
#   event_bus_name = aws_cloudwatch_event_bus.this.name
#   arn            = aws_sqs_queue.sqs.arn
#   target_id      = "SQSqueue"
#   depends_on     = [aws_sqs_queue.sqs, aws_sqs_queue_policy.eventbridge_to_sqs_policy]
# }

# # Allow EventBridge to invoke SQS
# resource "aws_sqs_queue_policy" "eventbridge_to_sqs_policy" {
#   queue_url = aws_sqs_queue.sqs.id
#   policy    = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "events.amazonaws.com"
#       },
#       "Action": "SQS:SendMessage",
#       "Resource": "${aws_sqs_queue.sqs.arn}"
#     }
#   ]
# }
# POLICY
# }

