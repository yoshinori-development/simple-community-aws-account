output "aws_cognito_user_pool_arn" {
  value = aws_cognito_user_pool.app.arn
}

output "aws_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

output "aws_cognito_user_pool_domain" {
  value = aws_cognito_user_pool_domain.app.domain
}
