terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# アカウントIDを取得するためのリソース
data "aws_caller_identity" "this" { }

module "sns" {
  source = "./modules/sns"
  topic_policy = {
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish"
      ],
      "Resource": "arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.this.account_id}:send_email",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${data.aws_caller_identity.this.account_id}"
        }
      }
    },
    {
      "Sid": "AWSEvents_datasync-task_Id64472599-fdd2-40b5-b657-394eb0838ddb",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.this.account_id}:send_email"
    }
  ]
}
  protocol = var.protocol
  endpoint = var.endpoint
}

module "event_bridge" {
  source = "./modules/eventbridge"
  event_pattern = {
    "source": ["aws.datasync"],
    "account": [data.aws_caller_identity.this.account_id],
    "time": [{
      "exists": true
    }],
    "resources": [{
      "prefix": "arn:aws:datasync:ap-northeast-1:${data.aws_caller_identity.this.account_id}:task/task-06e5cba3b238590af/execution/"
    }],
    "detail": {
      "State": ["SUCCESS"]
    }
  }
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