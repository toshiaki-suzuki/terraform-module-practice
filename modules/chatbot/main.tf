resource "awscc_chatbot_slack_channel_configuration" "this" {
  configuration_name = "terraform-slack-channel-config"
  iam_role_arn       = awscc_iam_role.this.arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id # AWS Chatbotのコンソール画面で事前に作成しておく
  sns_topic_arns     = [aws_sns_topic.this.arn]
}

resource "awscc_iam_role" "this" {
  role_name = "Terraform-ChatBot-Channel-Role"
  assume_role_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"]
}

resource "aws_sns_topic" "this" {
  name = var.sns_topic_name
}
