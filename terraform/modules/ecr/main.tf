data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "repositories" {
  for_each = toset(var.ecr_repositories)
  name     = each.key
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.encription.arn
  }
  image_scanning_configuration {
    scan_on_push = true
  }
  image_tag_mutability = "IMMUTABLE"
}

# 特定サービスのみへ権限を付与可能なキーポリシーについては以下参照
# https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-via-service
resource "aws_kms_alias" "encription" {
  name          = "alias/${var.tf.fullname}/ecr"
  target_key_id = aws_kms_key.encription.key_id
}

resource "aws_kms_key" "encription" {
  description             = "ECR repository encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = <<EOF
{
  "Id": "key-policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow encription",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.deploy_role_arn}"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "*"
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