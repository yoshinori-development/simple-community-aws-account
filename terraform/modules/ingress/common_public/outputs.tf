output "security_group_id" {
  value = aws_security_group.common-public.id
}

output "target_group_api_main_arn" {
  value = aws_lb_target_group.common-public-api-main.arn
}

output "target_group_app_community_arn" {
  value = aws_lb_target_group.common-public-app-community.arn
}
