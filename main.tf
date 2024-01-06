terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "sns" {
  source = "./modules/sns"
  topic_policy = var.topic_policy
  protocol = var.protocol
  endpoint = var.endpoint
}

module "event_bridge" {
  source = "./modules/eventbridge"
  event_pattern = var.event_pattern
  target_arn = module.sns.topic_arn
  input_paths = var.input_paths
  input_template = var.input_template
}
resource "aws_sns_topic" "sns_topic_for_chatbot" {
  name = "teffaform-chatbot-test"
}

module "chatbot" {
  source = "./modules/chatbot"
  slack_channel_id = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  sns_topic_arn = aws_sns_topic.sns_topic_for_chatbot.arn
}