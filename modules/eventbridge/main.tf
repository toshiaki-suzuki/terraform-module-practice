resource "aws_cloudwatch_event_rule" "event_bridge" {
  name        = "terraform_event_bridge"
  event_pattern = jsonencode(var.event_pattern)
}
