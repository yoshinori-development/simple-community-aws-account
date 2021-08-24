variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "ec2_tooling_id" {
  type = string
}

variable "ec2_nat_id" {
  type = string
}

variable "ec2_bastion_id" {
  type = string
}

variable "rds_core_id" {
  type = string
}

variable "rds_core_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_api_core_name" {
  type = string
}

variable "ecs_service_app_community_name" {
  type = string
}
