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

variable "deploy_user_arn" {
  type = string
}

variable "ecr_repositories" {
  type = list(string)
}