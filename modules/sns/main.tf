resource "aws_sns_topic" "this" {
  name = "send_email"
  policy = jsonencode(var.topic_policy)
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = var.protocol
  endpoint  = var.endpoint
}