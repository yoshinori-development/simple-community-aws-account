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
    fullname      = var.service.env == null ? var.service.name : "${var.service.name}-${var.service.env}"
    fullshortname = var.service.env == null ? var.service.name : "${var.service.shortname}-${var.service.env}"
  }
}

locals {
  fullname  = "${tf.flullname}-${local.service.fullname}"
  shortname = "${tf.shortname}-${local.service.fullshortname}"
}

variable "vpc" {
  type = object({
    id = string
  })
}

variable "private_subnet" {
  type = object({
    ids         = list(string)
    cidr_blocks = list(string)
  })
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
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

variable "container" {
  type = object({
    name = string
    port = number
  })
}

variable "ssm_parameter_prefix" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "service_discovery" {
  type = object({
    private_dns_namespace_id = string
  })
}

variable "alarm_threshold" {
  type = object({
    cpu_utilization    = string
    memory_utilization = string
  })
}

variable "sns_topic_arn" {
  type = string
}
