variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "subnet_group_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc" {
  type = object({
    id = string
  })
}

variable "public_subnet" {
  type = object({
    ids         = list(string)
    cidr_blocks = list(string)
  })
}

variable "hostedzone_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "hosts" {
  type = object({
    tracker = string
    console = string
  })
}

variable "ssl_policy" {
  type = string
  default = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
}

variable "certificate_arn" {
  type = string
}

variable "auth_console" {
  type = object({
    user_pool_arn       = string
    user_pool_client_id = string
    user_pool_domain    = string
  })
}