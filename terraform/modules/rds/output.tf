output "subnet_group_id" {
  value = aws_db_subnet_group.common.id
}

# output "encryption_kms_key_id" {
#   value = module.core-db.encryption_kms_key_id
# }
