terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.46.0"
    }
  }
  # backendに変数が使用できないためハードコード
  backend "s3" {
    bucket         = "ys-qn-tfstate"
    region         = "ap-northeast-1"
    key            = "qn/terraform.tfstate"
    dynamodb_table = "qn-tfstate-lock"
    encrypt        = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "chatbot-topics" {
  source  = "../../modules/chatbot_topics"
  tf      = local.tf
  administrator_role_arn = var.administrator_role_arn
}

module "ssm" {
  source  = "../../modules/ssm"
  tf      = local.tf
  administrator_role_arn = var.administrator_role_arn
  allow_session_manager_role_arns = concat(var.ssm.allow_session_manager_role_arns, [
    module.network.bastion_instance_role.arn,
    module.network.nat_instance_role.arn,
    module.tooling.instance_role.arn
  ])
  logging_bucket = {
    bucket = module.logging_bucket.bucket
    kms_key = module.logging_bucket.kms_key
  }
}

module "logging_bucket" {
  source  = "../../modules/logging_bucket"
  tf      = local.tf
  administrator_role_arn = var.administrator_role_arn
  allow_put_log_role_arns = [
    module.network.bastion_instance_role.arn,
    module.network.nat_instance_role.arn,
    module.tooling.instance_role.arn
  ]
}

module "network" {
  source  = "../../modules/network"
  tf      = local.tf
  vpc     = var.network.vpc
  subnets = var.network.subnets
  nat_instance = var.network.nat_instance
  bastion = var.network.bastion
  session_manager_policy = module.ssm.session_manager_policy
}

module "tooling" {
  source  = "../../modules/tooling"
  tf      = local.tf
  vpc     = module.network.vpc
  subnet = module.network.subnet-tooling
  instance = var.tooling.instance
  session_manager_policy = module.ssm.session_manager_policy
}

module "rds" {
  source            = "../../modules/rds"
  tf                = local.tf
  subnet_group_name = var.rds.subnet_group.name
  subnet_ids = module.network.subnet-database-ids
}

module "application" {
  source  = "../../modules/application"
  tf      = local.tf
  administrator_role_arn = var.administrator_role_arn
  vpc     = module.network.vpc
  subnet = {
    public = {
      ids = module.network.subnet-public-ids
      cidr_blocks = [
        var.network.subnets.public.a.cidr_block,
        var.network.subnets.public.c.cidr_block
      ]
    }
    application = {
      ids = module.network.subnet-application-ids
      cidr_blocks = [
        var.network.subnets.application.a.cidr_block,
        var.network.subnets.application.c.cidr_block
      ]
    }
  }
  ecs_cluster_name = var.application.ecs_cluster_name
  ecr_repositories = var.application.ecr_repositories
  ssm_parameter_prefix = var.application.ssm_parameter_prefix
  service_discovery_namespace = var.application.service_discovery_namespace
  services = var.application.services
  # services = merge(var.application.services, {
  #   api_core = merge(var.application.services.api_core, {
  #     kms_key_id = module.rds.encryption_kms_key_id
  #   })
  # })
}

# module "auth" {
#   source = "../../modules/auth"
#   tf      = local.tf
#   app = {
#     callback_urls = [
#       "https://${var.application.app_community.hosts.app_console}.${var.domain}",
#       "https://${var.hosts.app_console}.${var.domain}/oauth2/idpresponse"
#     ]
#   }
# }
