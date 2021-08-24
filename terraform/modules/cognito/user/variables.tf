variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "callback_urls" {
  type = list(string)
}

variable "user_pool_domain" {
  type = string
}
