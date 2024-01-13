terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# アカウントIDを取得するためのリソース
data "aws_caller_identity" "this" {}

# SSMパラメータストアから値を取得
data "aws_ssm_parameter" "slack_workspace_id" {
  name = "/terraform/module/practice/slack_workspace_id"
}

data "aws_ssm_parameter" "slack_channel_id" {
  name = "/terraform/module/practice/slack_channel_id"
}

data "aws_ssm_parameter" "sns_email_endpoint" {
  name = "/terraform/module/practice/sns_email_endpoint"
}

data "aws_ssm_parameter" "ses_domain_name" {
  name = "/terraform/module/practice/ses_domain_name"
}


# モジュールの呼び出し
module "sns" {
  source = "./modules/sns"
  topic_policy = {
    "Version" : "2008-10-17",
    "Id" : "__default_policy_ID",
    "Statement" : [
      {
        "Sid" : "__default_statement_ID",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ],
        "Resource" : "arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.this.account_id}:send_email",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceOwner" : "${data.aws_caller_identity.this.account_id}"
          }
        }
      },
      {
        "Sid" : "AWSEvents_datasync-task_Id64472599-fdd2-40b5-b657-394eb0838ddb",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Action" : "sns:Publish",
        "Resource" : "arn:aws:sns:ap-northeast-1:${data.aws_caller_identity.this.account_id}:send_email"
      }
    ]
  }
  protocol = "email"
  endpoint = data.aws_ssm_parameter.sns_email_endpoint.value
}

module "event_bridge" {
  source = "./modules/eventbridge"
  event_pattern = {
    "source" : ["aws.datasync"],
    "account" : [data.aws_caller_identity.this.account_id],
    "time" : [{
      "exists" : true
    }],
    "resources" : [{
      "prefix" : "arn:aws:datasync:ap-northeast-1:${data.aws_caller_identity.this.account_id}:task/task-06e5cba3b238590af/execution/"
    }],
    "detail" : {
      "State" : ["SUCCESS"]
    }
  }
  target_arn     = module.sns.topic_arn
  input_paths    = { "account" : "$.account", "resources" : "$.resources", "state" : "$.detail.State", "time" : "$.time" }
  input_template = <<EOF
    "DataSyncタスクが完了しました"
    "アカウント: <account>"
    "時刻: <time>"
    "リソース: <resources>"
    "状態: <state>"
    EOF
}

# module "chatbot" {
#   source             = "./modules/chatbot"
#   slack_channel_id   = data.aws_ssm_parameter.slack_channel_id.value
#   slack_workspace_id = data.aws_ssm_parameter.slack_workspace_id.value
#   sns_topic_name = "teffaform-chatbot-test"
# }

module "ses" {
  source = "./modules/ses"
  domain_name = data.aws_ssm_parameter.ses_domain_name.value
}