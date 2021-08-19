variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "vpc" {
  type = object({
    id = string
  }) 
}

variable "subnet" {
  type = object({
    ids = list(string)
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
    app_community = string
  }) 
}

variable "targets" {
  type = object({
    api_core = object({
      port = number
      health_check_path = string
    })
    app_community = object({
      port = number
      health_check_path = string
    })
  })
}

variable "ssl_policy" {
  type = string
  default = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
}

variable "certificate_arn" {
  type = string
}

variable "logging_bucket" {
  type = object({
    id = string
  })
}

variable "logging_bucket_prefix" {
  type = string
}
