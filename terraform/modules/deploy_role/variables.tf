variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "github" {
  type = object({
    organization = string
    id_provider = object({
      url = string
      client_id_list = list(string)
      thumbprint_list = list(string)
    })
  })
}

variable "roles_for_pass_role_arns" {
  type = list(string) 
}

variable "ecs_service_arns" {
  type = list(string)
}