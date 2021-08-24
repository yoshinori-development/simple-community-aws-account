output "instance_role" {
  value = aws_iam_role.tool
}

output "instance_id" {
  value = aws_instance.tool.id
}