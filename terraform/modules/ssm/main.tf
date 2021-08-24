data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 特定サービスのみへ権限を付与可能なキーポリシーについては以下参照
# https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-via-service
# resource "aws_kms_alias" "parameter_encription" {
#   name          = "alias/${var.tf.fullname}/ssm-parameter"
#   target_key_id = aws_kms_key.parameter_encription.key_id
# }

resource "aws_kms_key" "parameter_encription" {
  description             = "Ssm parameter encryption key"
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
        "Service": "ssm.amazonaws.com"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}",
          "kms:ViaService": "ssm.${data.aws_region.current.name}.amazonaws.com"
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
}

# 特定サービスのみへ権限を付与可能なキーポリシーについては以下参照
# https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-via-service
# Cloudwatch logsへ付与する権限は以下参照
# https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
# resource "aws_kms_alias" "session_manager_encription" {
#   name          = "alias/${var.tf.fullname}/ssm-session-manager"
#   target_key_id = aws_kms_key.session_manager_encription.key_id
# }

resource "aws_kms_key" "session_manager_encription" {
  description             = "Ssm session manager encryption key"
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
        "AWS": ${jsonencode(var.allow_session_manager_role_arns)}
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt",
        "kms:Encrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"
        }
      }
    },
    {
      "Sid": "Cloudwatch logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*",
      "Condition": {
        "ArnEquals": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.tf.fullname}-session-manager"
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
}

resource "aws_cloudwatch_log_group" "session-manager" {
  name              = "${var.tf.fullname}-session-manager"
  retention_in_days = 0
  kms_key_id        = aws_kms_key.session_manager_encription.arn
}

# Session ManagerのIAM Policyは以下を参照
# https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html
resource "aws_iam_policy" "session-manager" {
  name        = "${var.tf.fullname}-session-manager"
  description = "${var.tf.fullname}-session-manager"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:UpdateInstanceInformation",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${var.logging_bucket.arn}/session-manager/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "kms:GenerateDataKey",
      "Resource": "*"
    }
  ]
}
EOF
}
