resource "aws_cognito_user_pool" "user" {
  name             = var.tf.fullname
  alias_attributes = ["email", "preferred_username"]
  username_configuration {
    case_sensitive = true
  }
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
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "user_community" {
  name                                 = "community"
  user_pool_id                         = aws_cognito_user_pool.user.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = var.callback_urls
  generate_secret                      = true
}

resource "aws_cognito_user_pool_domain" "user_community" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.user.id
}
