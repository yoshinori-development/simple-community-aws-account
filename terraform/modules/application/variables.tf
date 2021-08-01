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

variable "subnet" {
  type  = object({
    public = object({
      ids         = list(string)
      cidr_blocks = list(string)
    })
    application = object({
      ids         = list(string)
      cidr_blocks = list(string)
    })
  })
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecr_repositories" {
  type = list(string)
}

variable "ssm_parameter_prefix" {
  type = string
}

variable "service_discovery_namespace" {
  type = string
}

# variable "sns_topic_arn" {
#   type = string
# }
 
variable "services" {
  type = object({
    api_core = object({
      env = string
      ecs_task_definition = object({
        name = string
      })
      # kms_key_id = string
      alarm_threshold = object({
        cpu_utilization    = string
        memory_utilization = string
      })
    })
    app_community = object({
      env = string
      ecs_task_definition = object({
        name = string
      })
      ingress = object({
        host = string
        container_name = string
        container_port = number
      })
      alarm_threshold = object({
        cpu_utilization    = string
        memory_utilization = string
      })
    })
  })
}
