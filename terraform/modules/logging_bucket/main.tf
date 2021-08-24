data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 特定サービスのみへ権限を付与可能なキーポリシーについては以下参照
# https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-via-service
# S3バケットへ付与するポリシーは以下を参照
# https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/UsingKMSEncryption.html
# resource "aws_kms_alias" "logging" {
#   name          = "alias/${var.tf.fullname}/log-bucket"
#   target_key_id = aws_kms_key.logging.key_id
# }

# resource "aws_kms_key" "logging" {
#   description             = "log bucket encryption key"
#   deletion_window_in_days = 7
#   enable_key_rotation = true
#   policy = <<EOF
# {
#   "Id": "key-policy",
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "Allow encription ",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": ${jsonencode(var.allow_put_log_role_arns)}
#       },
#       "Action": [
#         "kms:GenerateDataKey",
#         "kms:Decrypt",
#         "kms:Encrypt"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringEquals": {
#           "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"
#         }
#       }
#     },
#     {
#       "Sid": "s3",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "s3.amazonaws.com"
#       },
#       "Action": [
#         "kms:Decrypt",
#         "kms:GenerateDataKey"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "StringEquals": {
#           "kms:EncryptionContext:x-amz-server-side-encryption-context": "arn:aws:s3:::${local.bucket_name}"
#         }
#       }
#     },
#     {
#       "Sid": "Allow access for Key Administrators",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "${var.administrator_role_arn}"
#       },
#       "Action": [
#         "kms:*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

locals {
  bucket_name = "${var.tf.fullname}-logging"
  prefix_alb  = "alb"
}

resource "aws_s3_bucket" "logging" {
  bucket = local.bucket_name
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logging" {
  bucket                  = aws_s3_bucket.logging.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::582318560864:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.logging.id}/${local.prefix_alb}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.logging.id}/${local.prefix_alb}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.logging.id}"
    }
  ]
}
POLICY
}