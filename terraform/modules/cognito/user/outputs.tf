output "user_pool_arn" {
  value = aws_cognito_user_pool.user.arn
}

output "community_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_community.id
}

output "community_user_pool_domain" {
  value = aws_cognito_user_pool_domain.user_community.domain
}
