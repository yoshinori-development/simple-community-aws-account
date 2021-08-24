variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "service" {
  type = object({
    name      = string
    shortname = string
    env       = string
  })
}

locals {
  service = {
    fullname      = var.service.env == "" ? var.service.name : "${var.service.name}-${var.service.env}"
    fullshortname = var.service.env == "" ? var.service.name : "${var.service.shortname}-${var.service.env}"
  }
}

locals {
  fullname  = "${var.tf.fullname}-${local.service.fullname}"
  shortname = "${var.tf.shortname}-${local.service.fullshortname}"
}

variable "vpc" {
  type = object({
    id = string
  })
}

variable "subnet" {
  type = object({
    ids         = list(string)
    cidr_blocks = list(string)
  })
}

variable "desired_count" {
  type = number
}

variable "load_balancer" {
  type = object({
    security_group_id = string
    target_group_arn  = string
    container = object({
      name = string
      port = number
    })
  })
}

variable "ecs_cluster" {
  type = object({
    arn  = string
    name = string
  })
}

variable "ecs_task_definition" {
  type = object({
    name = string
  })
}

variable "ecs_service" {
  type = object({
    capacity_provider_strategy = object({
      capacity_provider = string
      weight            = number
    })
  })
}

variable "ssm_parameter_prefix" {
  type = string
}

variable "kms_key_ids" {
  type = object({
    rds_core = string
  })
}

variable "service_discovery" {
  type = object({
    private_dns_namespace_id = string
  })
}

variable "alarm_thresholds" {
  type = object({
    cpu_utilization    = string
    memory_utilization = string
  })
}

# variable "sns_topic_arn" {
#   type = string
# }
