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
