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
    id = string
  })
}

variable "instance" {
  type = object({
    ami = string
    instance_type = string
  })
}

variable "session_manager_policy" {
  type = object({
    arn = string
  })
}
