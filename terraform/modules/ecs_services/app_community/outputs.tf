
output "task-role" {
  value = aws_iam_role.task-role
}

output "task-execution-role" {
  value = aws_iam_role.task-execution-role
}

output "ecs-service-name" {
  value = local.service.fullname
}