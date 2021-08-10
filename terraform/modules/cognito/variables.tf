variable "tf" {
  type = object({
    name          = string
    shortname     = string
    env           = string
    fullname      = string
    fullshortname = string
  })
}

variable "app" {
  type = object({
    callback_urls = list(string)
    user_pool_domain = string
  })
}
