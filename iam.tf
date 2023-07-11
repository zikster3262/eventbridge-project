
// create iam policy for lambda enabling to write events to eventbridge bus
resource "aws_iam_policy" "this" {
  name        = "relayer-eventbus"
  description = "Policy for accessing the putting events into eventbus from lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadWriteTable",
            "Effect": "Allow",
            "Action": [
              "events:PutEvents",
              "events:PutRule",
              "events:PutTargets"
            ],
            "Resource": "${aws_cloudwatch_event_bus.this.arn}"
        }
    ]
}
EOF
}

// Attach policy to the lambda exec role
resource "aws_iam_role_policy_attachment" "lambda_update_policy" {
  role       = module.relayer.lambda_exec_role_name
  policy_arn = aws_iam_policy.this.arn
}
