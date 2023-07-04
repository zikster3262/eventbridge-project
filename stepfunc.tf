# Create an SQS queue
resource "aws_sqs_queue" "sqs" {
  name = "apigw-create"
}

resource "aws_sqs_queue" "update" {
  name = "apigw-update"
}

resource "aws_sqs_queue" "delete" {
  name = "apigw-delete"
}


resource "aws_sfn_state_machine" "send_to_sqs_state_machine" {
  name       = "send-to-sqs-state-machine"
  role_arn   = aws_iam_role.step_functions_role.arn
  definition = <<EOF
{
  "Comment": "A Step Functions state machine that sends data to SQS",
  "StartAt": "Choice",
  "States": {
    "Choice": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.action[0]",
          "StringMatches": "CREATE",
          "Next": "SendToCreateSQS"
        },
        {
          "Variable": "$.action[0]",
          "StringMatches": "UPDATE",
          "Next": "SendToUpdateSQS"
        },
        {
          "Variable": "$.action[0]",
          "StringMatches": "DELETE",
          "Next": "SendToDeleteSQS"
        }
      ],
      "InputPath": "$.detail"
    },
    "SendToCreateSQS": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage",
      "Parameters": {
        "QueueUrl": "${aws_sqs_queue.sqs.id}",
        "MessageBody": "$.input"
      },
      "End": true
    },
    "SendToUpdateSQS": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage",
      "Parameters": {
        "QueueUrl": "${aws_sqs_queue.update.id}",
        "MessageBody": "$.input"
      },
      "End": true
    },
    "SendToDeleteSQS": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage",
      "Parameters": {
        "QueueUrl": "${aws_sqs_queue.delete.id}",
        "MessageBody": "$.input"
      },
      "End": true
    }
  }
}
EOF
}


resource "aws_iam_role" "step_functions_role" {
  name = "step-functions-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send_to_sqs_policy" {
  name        = "send-to-sqs-policy"
  description = "Allows executing Step Functions and sending messages to SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "states:StartExecution"
      ],
      "Resource": "${aws_sfn_state_machine.send_to_sqs_state_machine.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.sqs.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.update.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.delete.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send_to_sqs_policy_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.send_to_sqs_policy.arn
}

# Create an EventBridge rule
resource "aws_cloudwatch_event_rule" "step" {
  name           = "api-gw-event-rule-step"
  description    = "EventBridge rule for sending events to Step func"
  event_bus_name = aws_cloudwatch_event_bus.this.name
  role_arn       = aws_iam_role.eventbridge_role.arn

  is_enabled = true
  event_pattern = jsonencode({
    source = [
      "custom.aws.replayer"
    ]
  })
}

resource "aws_cloudwatch_event_target" "step_functions_target" {
  rule           = aws_cloudwatch_event_rule.step.name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  target_id      = "step-functions-target"
  arn            = aws_sfn_state_machine.send_to_sqs_state_machine.arn
  role_arn       = aws_iam_role.eventbridge_role.arn
}

resource "aws_iam_role" "eventbridge_role" {
  name               = "eventbridge-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "eventbridge_policy" {
  name        = "eventbridge-policy"
  description = "Policy allowing EventBridge to send events to Step Functions"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowStepFunctionsInvocation",
      "Effect": "Allow",
      "Action": "states:StartExecution",
      "Resource": "${aws_sfn_state_machine.send_to_sqs_state_machine.arn}" 
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eventbridge_attachment" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_policy.arn
}
