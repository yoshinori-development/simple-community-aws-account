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
    cidr_block = string
  })
}

variable "subnets" {
  type = object({
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
}

variable "nat_instance" {
  type = object({
    ami           = string
    instance_type = string
  })
}

variable "bastion" {
  type = object({
    ami_name_filter = string
    instance_type   = string
  })
}

variable "session_manager_policy" {
  type = object({
    arn = string
  })
}


variable "multi_az" {
  type = bool
}