resource "aws_cognito_user_pool" "app" {
  name                     = var.tf.fullname
  username_attributes      = ["email"]
  username_configuration {
    case_sentisitive = true
  }
  # auto_verified_attributes = ["email"]
  # device_configuration
  # email_configuration 
  # email_verification_message
  # email_verification_subject
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  password_policy {
    minimum_length                   = 16
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  mfa_configuration          = "OFF"
  # sms_authentication_message = "認証コードは {####} です。"
  # sms_configuration {
  #   external_id    = random_uuid.sms.result
  #   sns_caller_arn = aws_iam_role.sms.arn
  # }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name                                 = "app"
  user_pool_id                         = aws_cognito_user_pool.console_user.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
  callback_urls = var.callback_urls
  # callback_urls = [
  #   "https://${var.hosts.app_console}.${var.domain}",
  #   "https://${var.hosts.app_console}.${var.domain}/oauth2/idpresponse"
  # ]
  generate_secret = true
}

resource "aws_cognito_user_pool_domain" "console_user" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.console_user.id
}

resource "random_uuid" "sms" {
}

resource "aws_iam_role" "sms" {
  name               = "${var.tf.fullname}-${local.name}-sms-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cognito-idp.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${random_uuid.sms.result}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "sms" {
  name        = "${var.tf.fullname}-${local.name}-policy"
  description = "${var.tf.fullname} ${local.name} policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:publish"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sms" {
  role       = aws_iam_role.sms.name
  policy_arn = aws_iam_policy.sms.arn
}