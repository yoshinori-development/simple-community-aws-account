data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_db_parameter_group" "default" {
  name   = "${var.tf.fullname}-${var.db_instance.identifier}"
  family = "mysql8.0"

  parameter {
    name         = "explicit_defaults_for_timestamp"
    value        = "0"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "character_set_client"
    value        = "utf8mb4"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "character_set_filesystem"
    value        = "utf8mb4"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "collation_connection"
    value        = "utf8mb4_general_ci"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "collation_server"
    value        = "utf8mb4_general_ci"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "default_collation_for_utf8mb4"
    value        = "utf8mb4_general_ci"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "log_bin_trust_function_creators"
    value        = "1"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "pending-reboot"
  }
  tags = {
    Name = "${var.tf.fullname}-${var.db_instance.identifier}"
  }
}

resource "aws_db_option_group" "default" {
  name                     = "${var.tf.fullname}-${var.db_instance.identifier}"
  option_group_description = "${var.tf.fullname}-${var.db_instance.identifier}"
  engine_name              = "mysql"
  major_engine_version     = "8.0"
  tags = {
    Name = "${var.tf.fullname}-${var.db_instance.identifier}"
  }

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY"
    }
    option_settings {
      name  = "SERVER_AUDIT_QUERY_LOG_LIMIT"
      value = "20480"
    }
  }
}

resource "aws_security_group" "default" {
  name        = "${var.tf.fullname}-${var.db_instance.identifier}"
  description = "${var.tf.fullname}-${var.db_instance.identifier}"
  vpc_id      = var.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingresses" {
  for_each = {
    for key, id in var.allowed_security_group_ids : key => id
  }
  type                     = "ingress"
  from_port                = var.db_instance.port
  to_port                  = var.db_instance.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.default.id
}

resource "aws_db_instance" "default" {
  name                                = var.db_instance.dbname
  engine                              = "mysql"
  engine_version                      = var.db_instance.engine_version
  multi_az                            = var.db_instance.multi_az
  parameter_group_name                = aws_db_parameter_group.default.name
  option_group_name                   = aws_db_option_group.default.name
  db_subnet_group_name                = var.subnet_group_id
  instance_class                      = var.db_instance.instance_class
  identifier                          = var.db_instance.identifier
  storage_type                        = var.db_instance.storage_type
  allocated_storage                   = var.db_instance.allocated_storage
  max_allocated_storage               = var.db_instance.max_allocated_storage
  allow_major_version_upgrade         = var.db_instance.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.db_instance.auto_minor_version_upgrade
  port                                = var.db_instance.port
  vpc_security_group_ids              = [aws_security_group.default.id]
  publicly_accessible                 = var.db_instance.publicly_accessible
  username                            = var.db_instance.username
  password                            = aws_ssm_parameter.rds_password.value
  iam_database_authentication_enabled = var.db_instance.iam_database_authentication_enabled
  performance_insights_enabled        = var.db_instance.performance_insights_enabled
  performance_insights_kms_key_id     = var.db_instance.performance_insights_enabled ? aws_kms_key.encription.arn : null
  storage_encrypted                   = var.db_instance.storage_encrypted
  kms_key_id                          = aws_kms_key.db_encription.arn
  delete_automated_backups            = var.db_instance.delete_automated_backups
  deletion_protection                 = var.db_instance.deletion_protection
  backup_retention_period             = var.db_instance.backup_retention_period
  backup_window                       = var.db_instance.backup_window
  maintenance_window                  = var.db_instance.maintenance_window
  enabled_cloudwatch_logs_exports     = var.db_instance.enabled_cloudwatch_logs_exports
  final_snapshot_identifier = "${var.tf.fullname}-${formatdate("YYYY-mm-DD", timestamp())}"
}

resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "rds_password" {
  name   = var.ssm_parameters.database_password.name
  type   = "SecureString"
  key_id = var.ssm_parameters.kms_key_id
  value  = random_password.password.result
}

# 特定サービスのみへ権限を付与可能なキーポリシーについては以下参照
# https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-via-service
# RDSに必要な権限は以下参照
# https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/UserGuide/Overview.Encryption.Keys.html
# パフォーマンスインサイトに必要な権限は以下参照
# https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/UserGuide/USER_PerfInsights.access-control.html#USER_PerfInsights.access-control.cmk-policy
resource "aws_kms_alias" "encription" {
  name          = "alias/${var.tf.fullname}/rds-core"
  target_key_id = aws_kms_key.db_encription.key_id
}

resource "aws_kms_key" "encription" {
  description             = "RDS core encryption key"
  deletion_window_in_days = 7
  enable_key_rotation = true
  policy = <<EOF
{
  "Id": "key-policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow encription and performance insights",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}",
          "kms:ViaService": "rds.${data.aws_region.current.name}.amazonaws.com"
        },
        "ForAnyValue:StringEquals": {
          "kms:EncryptionContext:aws:pi:service": "rds",
          "kms:EncryptionContext:service": "pi",
          "kms:EncryptionContext:aws:rds:db-id": "${var.db_instance.identifier}"
        }
      }
    },
    {
      "Sid": "Allow access for Key Administrators",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.administrator_role_arn}"
      },
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Cloudwatch Metric Alerms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_cpu_utilization_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.cpu_utilization
  alarm_description   = "Average database CPU utilization over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_credit_balance_low" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_cpu_credit_balance_low"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.cpu_credit_balance
  alarm_description   = "Average database cpu credit balance over last 5 minutes low"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space_low" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_free_storage_space_threshold"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.free_storage_space
  alarm_description   = "Average database free storage space over last 5 minutes low"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory_low" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_freeable_memory_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.freeable_memory
  alarm_description   = "Average database freeable memory over last 5 minutes low"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "swap_usage_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_swap_usage_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "SwapUsage"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.swap_usage
  alarm_description   = "Average database swap usage over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "connections_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_connections_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.connections
  alarm_description   = "Average database connections over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "burst_balance_low" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_burst_balance_low"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "BurstBalance"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.burst_balance
  alarm_description   = "Average burst balance over last 5 minutes low"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs_io_balance_low" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_ebs_io_balance_low"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "EBSIOBalance"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.ebs_io_balance
  alarm_description   = "Average ebs io balance over last 5 minutes low"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs_byte_balance_low" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_ebs_byte_balance_low"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "EBSByteBalance"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.ebs_byte_balance
  alarm_description   = "Average ebs byte balance over last 5 minutes low"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "read_iops_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_read_iops_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.read_iops
  alarm_description   = "Average read_iops over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
  tags = var.tf.tags
}

resource "aws_cloudwatch_metric_alarm" "write_iops_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_write_iops_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "WriteIOPS"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.write_iops
  alarm_description   = "Average write_iops over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "read_throughtput_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_read_throughtput_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "ReadThroughput"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.read_throughtput
  alarm_description   = "Average read_throughtput over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "write_throughtput_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_write_throughtput_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "WriteThroughput"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.write_throughtput
  alarm_description   = "Average write_throughtput over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "network_receive_throughtput_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_network_receive_throughtput_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "NetworkReceiveThroughput"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.network_receive_throughtput
  alarm_description   = "Average network receive throughtput over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}

resource "aws_cloudwatch_metric_alarm" "network_transmit_throughtput_high" {
  alarm_name          = "${var.tf.fullname}_rds_${aws_db_instance.default.name}_network_transmit_throughtput_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "3"
  metric_name         = "NetworkTransmitThroughput"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alarm.thresholds.network_transmit_throughtput
  alarm_description   = "Average network transmit throughtput over last 5 minutes high"
  alarm_actions       = [var.alarm.sns_topic_arn]
  ok_actions          = [var.alarm.sns_topic_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.id
  }
}
