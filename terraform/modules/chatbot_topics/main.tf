# ChatBot自体はTerraform未対応のため手動で設定
# SNS Topicのみ

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  notification = "${var.tf.fullname}-notification"
}

resource "aws_sns_topic" "notification" {
  name              = local.notification
  display_name      = local.notification
  kms_master_key_id = aws_kms_key.topic_encription.key_id
  policy            = <<EOF
{
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
        "SNS:Publish",
        "SNS:RemovePermission",
        "SNS:SetTopicAttributes",
        "SNS:DeleteTopic",
        "SNS:ListSubscriptionsByTopic",
        "SNS:GetTopicAttributes",
        "SNS:Receive",
        "SNS:AddPermission",
        "SNS:Subscribe"
      ],
      "Resource": "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.notification}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${data.aws_caller_identity.current.account_id}"
        }
      }
    }
  ]
}
EOF
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "numRetries": 3,
      "numNoDelayRetries": 0,
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numMinDelayRetries": 0,
      "numMaxDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false
  }
}
EOF
  tags = {
    Name = "${var.tf.fullname}-${local.notification}"
  }
}

resource "aws_sns_topic_subscription" "notification" {
  topic_arn = aws_sns_topic.notification.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

# 特定サービスのみへ権限を付与可能なキーポリシーについては以下参照
# https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-via-service
# トピックに必要な権限は以下参照
# https://docs.aws.amazon.com/ja_jp/sns/latest/dg/sns-key-management.html
# resource "aws_kms_alias" "topic_encription" {
#   name          = "alias/${var.tf.fullname}/topic"
#   target_key_id = aws_kms_key.topic_encription.key_id
# }

resource "aws_kms_key" "topic_encription" {
  description             = "Notification topic encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = <<EOF
{
  "Id": "key-policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow encription topic",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudwatch.amazonaws.com"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": [
            "sns.${data.aws_region.current.name}.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "Allow access for Key Administrators",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.administrator_role_arn}"
      },
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  tags = {
    Name = "${var.tf.fullname}-rds-core"
  }
}
