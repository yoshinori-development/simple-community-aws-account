output "subnet_group_id" {
  value = aws_db_subnet_group.common.id
}

output "encryption_kms_key_id" {
  value = aws_kms_key.core.key_id
}
