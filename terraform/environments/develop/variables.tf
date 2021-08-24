variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "shortname" {
  type = string
}

variable "env" {
  type = string
}

locals {
  tf = {
    name          = var.name
    shortname     = var.shortname
    env           = var.env
    fullname      = "${var.name}-${var.env}"
    fullshortname = "${var.shortname}-${var.env}"
  }
  fqdn = {
    app_community = var.ecs_services.app_community.dns.external_host == "" ? var.domain : "${var.ecs_services.app_community.dns.external_host}.${var.domain}"
  }
}

variable "administrator_role_arn" {
  type = string
}

variable "domain" {
  type = string
}

variable "hostedzone_id" {
  type = string
}

variable "ssm" {
  type = object({
    allow_session_manager_role_arns = list(string)
  })
}

variable "network" {
  type = object({
    vpc = object({
      cidr_block = string
    })
    subnets = object({
      public = object({
        a = object({
          cidr_block = string
        })
        c = object({
          cidr_block = string
        })
      })
      application = object({
        a = object({
          cidr_block = string
        })
        c = object({
          cidr_block = string
        })
      })
      database = object({
        a = object({
          cidr_block = string
        })
        c = object({
          cidr_block = string
        })
      })
      tooling = object({
        cidr_block = string
      })
    })
    nat_instance = object({
      ami           = string
      instance_type = string
    })
    bastion = object({
      ami_name_filter = string
      instance_type   = string
    })
    multi_az = bool
  })
}

variable "tooling" {
  type = object({
    instance = object({
      is_spot = bool
      ami           = string
      instance_type = string
    })
  })
}

variable "rds" {
  type = object({
    core = object({
      allowed_security_group_ids = list(string)
      ssm_parameters = object({
        database_password = object({
          name            = string
          with_decryption = string
        })
      })
      db_instance = object({
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
        performance_insights_enabled        = bool
        storage_encrypted                   = bool
        delete_automated_backups            = bool
        deletion_protection                 = bool
        backup_retention_period             = number
        backup_window                       = string
        maintenance_window                  = string
        enabled_cloudwatch_logs_exports     = list(string)
        monitoring_interval                 = number
      })
      alarm = object({
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
      })
    })
  })
}

variable "ecs_cluster" {
  type = object({
    name               = string
    capacity_providers = list(string)
  })
}

variable "ecr_repositories" {
  type = list(string)
}

variable "ecs_services" {
  type = object({
    api_core = object({
      env = string
      ecs_task_definition = object({
        name = string
      })
      capacity_provider_strategy = object({
        capacity_provider = string
        weight            = number
      })
      desired_count = number
      container = object({
        name = string
        port = number
      })
      health_check_pach = string
      alarm_thresholds = object({
        cpu_utilization    = string
        memory_utilization = string
      })
    })
    app_community = object({
      env = string
      ecs_task_definition = object({
        name = string
      })
      capacity_provider_strategy = object({
        capacity_provider = string
        weight            = number
      })
      desired_count = number
      dns = object({
        external_host = string
      })
      container = object({
        name = string
        port = number
      })
      health_check_pach = string
      alarm_thresholds = object({
        cpu_utilization    = string
        memory_utilization = string
      })
    })
  })
}

variable "ssm_parameter_prefix" {
  type = string
}

variable "service_discovery_namespace" {
  type = string
}

variable "cognito" {
  type = object({
    user = object({
      user_pool_domain = string
    })
  })
}

# variable "slack" {
#   type = object({
#     webhook_url = string
#     channel = string
#     username = string
#   })
# }
