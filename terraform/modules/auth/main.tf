module "app" {
  source = "./app"
  tf      = var.tf
  callback_urls = var.app.callback_urls
 #     "https://${var.hosts.app_console}.${var.domain}",
  #   "https://${var.hosts.app_console}.${var.domain}/oauth2/idpresponse"
  user_pool_domain = var.app.user_pool_domain
}
