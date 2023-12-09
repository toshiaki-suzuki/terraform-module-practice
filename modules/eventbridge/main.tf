resource "aws_cloudwatch_event_rule" "event_bridge" {
  name        = "terraform_event_bridge"
  event_pattern = jsonencode(var.event_pattern)
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.event_bridge.name
  target_id = "SendToSNS"
  arn       = var.target_arn
}
