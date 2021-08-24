variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "administrator_role_arn" {
  type = string
}

variable "vpc" {
  type = object({
    id = string
  })
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  type = list(string)
}

variable "ssm" {
  type = object({
    kms_key_id = string
    parameters = object({
      database_password = object({
        name = string
      })
    })
  })
}

variable "db_instance" {
  type = object({
    instance_class                      = string
    engine_version                      = string
    identifier                          = string
    multi_az                            = bool
    port                                = number
    dbname                              = string
    storage_type                        = string
    allocated_storage                   = number
    max_allocated_storage               = number
    allow_major_version_upgrade         = bool
    auto_minor_version_upgrade          = bool
    publicly_accessible                 = bool
    username                            = string
    iam_database_authentication_enabled = bool
    storage_encrypted                   = bool
    performance_insights_enabled        = bool
    delete_automated_backups            = bool
    deletion_protection                 = bool
    backup_retention_period             = number
    backup_window                       = string
    maintenance_window                  = string
    enabled_cloudwatch_logs_exports     = list(string)
    monitoring_interval                 = number
  })
}

variable "alarm" {
  type = object({
    thresholds = object({
      cpu_utilization              = string
      cpu_credit_balance           = string
      free_storage_space           = string
      freeable_memory              = string
      swap_usage                   = string
      connections                  = string
      burst_balance                = string
      ebs_io_balance               = string
      ebs_byte_balance             = string
      read_iops                    = string
      write_iops                   = string
      read_throughtput             = string
      write_throughtput            = string
      network_receive_throughtput  = string
      network_transmit_throughtput = string
    })
    # sns_topic_arn = string
  })
}
