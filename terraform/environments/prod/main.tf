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

module "rds_core" {
  source            = "../../modules/rds/core"
  tf                = local.tf
  administrator_role_arn = var.administrator_role_arn
  vpc     = module.network.vpc
  subnet_ids = module.network.subnet-database-ids
  allowed_security_group_ids = var.rds.core.allowed_security_group_ids
  ssm = {
    parameters = var.rds.core.ssm_parameters
    kms_key_id = module.ssm.kms_key.id
  }
  db_instance = var.rds.core.db_instance
  alarm = var.rds.core.alarm
}

resource "aws_route53_zone" "primary" {
  name = var.domain
}

module "acm" {
  source = "../../modules/acm"
  tf = local.tf
  hostedzone_id   = aws_route53_zone.primary.zone_id
  domain          = var.domain
}

module "ingress_common_public" {
  source = "../../modules/ingress/common_public"
  tf                = local.tf
  vpc     = module.network.vpc
  subnet = {
    ids = module.network.subnet-public-ids
  }
  hostedzone_id   = aws_route53_zone.primary.zone_id
  domain          = var.domain
  hosts = {
    app_community = var.ecs_services.app_community.dns.external_host
  }
  certificate_arn = module.acm.current_region_certificate_arn
}

resource "aws_service_discovery_private_dns_namespace" "private_dns" {
  name = var.service_discovery_namespace
  vpc  = module.network.vpc.id
}

module "ecr" {
  source = "../../modules/ecr"
  tf = local.tf
  administrator_role_arn = var.administrator_role_arn
  deploy_user_arn = aws_iam_user.github_deployer.arn
  ecr_repositories = var.ecr_repositories
}

resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name
  capacity_providers = ["FARGATE"]
}

module "ecs_service_api_core" {
  source = "../../modules/ecs_services/api_core"
  tf = local.tf
  service = {
    name = "api-core"
    shortname = "ac"
    env  = ""
  }
  vpc = module.network.vpc
  subnet = {
    ids = module.network.subnet-application-ids
    cidr_blocks = [
      var.network.subnets.application.a.cidr_block,
      var.network.subnets.application.c.cidr_block
    ]
  }
  desired_count = var.ecs_services.api_core.desired_count
  load_balancer = {
    security_group_id = module.ingress_common_public.security_group_id
    target_group_arn = module.ingress_common_public.target_group_api_core_arn
    container = var.ecs_services.api_core.container
  }
  ecs_cluster = {
    arn  = aws_ecs_cluster.cluster.arn
    name = aws_ecs_cluster.cluster.name
  }
  ecs_task_definition = var.ecs_services.api_core.ecs_task_definition
  ssm_parameter_prefix = var.ssm_parameter_prefix
  kms_key_ids = {
    rds_core = module.rds_core.encryption_kms_key_id
  }
  service_discovery = {
    private_dns_namespace_id = aws_service_discovery_private_dns_namespace.private_dns.id
  }
  alarm_thresholds = var.ecs_services.api_core.alarm_thresholds
  # sns_topic_arn = module.metrics_notify_slack.this_slack_topic_arn
}

module "ecs_service_app_community" {
  source = "../../modules/ecs_services/app_community"
  tf = local.tf
  service = {
    name = "app-community"
    shortname = "com"
    env  = ""
  }
  vpc = module.network.vpc
  subnet = {
    ids = module.network.subnet-application-ids
    cidr_blocks = [
      var.network.subnets.application.a.cidr_block,
      var.network.subnets.application.c.cidr_block
    ]
  }
  desired_count = var.ecs_services.app_community.desired_count
  load_balancer = {
    security_group_id = module.ingress_common_public.security_group_id
    target_group_arn = module.ingress_common_public.target_group_app_community_arn
    container = var.ecs_services.app_community.container
  }
  ecs_cluster = {
    arn  = aws_ecs_cluster.cluster.arn
    name = aws_ecs_cluster.cluster.name
  }
  ecs_task_definition = var.ecs_services.app_community.ecs_task_definition
  alarm_thresholds = var.ecs_services.app_community.alarm_thresholds
  # sns_topic_arn = module.metrics_notify_slack.this_slack_topic_arn
}

# module "health-check" {
#   providers = {
#     aws = aws.global
#   }
#   source = "../../modules/healthcheck"

#   infra = var.infra
#   fqdn = "${var.hosts.app_tracker.develop}.${var.domain}"
#   console_fqdn = "${var.hosts.app_console.develop}.${var.domain}"
#   slack = {
#     webhook_url = var.slack.webhook_url
#     channel     = var.slack.channel
#     username    = var.slack.username
#   }
# }

resource "aws_iam_user" "github_deployer" {
  name = "github_deployer"
  path = "/system/"
}

resource "aws_iam_user_policy" "github_deployer" {
  name = "github_deployer"
  user = aws_iam_user.github_deployer.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages"
        ],
        "Effect": "Allow",
        "Resource": [
          "*"
        ]
      },
      {
        "Action": [
          "kms:*"
        ],
        "Effect": "Allow",
        "Resource": [
          "*"
        ]
      }
    ]
  })
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
