variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "hostedzone_id" {
  type = string
}

variable "domain" {
  type = string
}