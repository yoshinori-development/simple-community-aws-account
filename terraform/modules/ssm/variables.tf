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

variable "allow_session_manager_role_arns" {
  type = list(string)
}

variable "logging_bucket" {
  type = object({
    bucket = object({
      arn = string
    })
    kms_key = object({
      arn = string
    })
  })
}
