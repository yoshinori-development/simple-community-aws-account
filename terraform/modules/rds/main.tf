resource "aws_db_subnet_group" "common" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids
  tags = {
    Name = var.tf.fullname
  }
}

# module "core-db" {
#   source            = "../../modules/rds/core-mysql8"
#   tf                = local.tf
#   administrator_role_arn = var.administrator_role_arn
#   vpc               = module.network.vpc
#   subnet_group_id   = module.rds.subnet_group_id
#   allowed_security_group_ids = concat(var.rds.core_db.allowed_security_group_ids, [
#     module.network.bastion_security_group.id
#     # module.api-core.aws_security_group_id,
#   ])
#   ssm_parameters = merge(var.rds.core_db.ssm_parameters, {
#     kms_key_id = module.ssm.kms_key.key_id
#   })
#   db_instance = var.rds.core_db.db_instance
#   alarm = {
#     thresholds = var.rds.core_db.alarm.thresholds
#     sns_topic_arn = module.chatbot-topics.notification-topic.arn
#   }
# }