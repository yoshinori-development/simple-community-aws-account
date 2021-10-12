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
  task_execution_role_arns = [
    module.ecs_service_api_main.task-execution-role.arn
  ]
  allow_session_manager_role_arns = concat(var.ssm.allow_session_manager_role_arns, [
    module.network.bastion_instance_role.arn,
    module.network.nat_instance_role.arn,
    module.tooling.instance_role.arn
  ])
  logging_bucket = module.logging_bucket.bucket
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

module "start_stop_resources" {
  source  = "../../modules/start_stop_resources"
  tf      = local.tf
  ec2_tooling_id = module.tooling.instance_id
  ec2_nat_id = module.network.nat_instance_a_id
  ec2_bastion_id = module.network.bastion_instance_id
  rds_main_id = module.rds_main.rds_instance_id
  rds_main_name = var.rds.main.db_instance.identifier
  ecs_cluster_name = var.ecs_cluster.name
  ecs_service_api_main_name = "api-main"
  ecs_service_app_community_name = "app-community"
}

module "network" {
  source  = "../../modules/network"
  tf      = local.tf
  vpc     = var.network.vpc
  subnets = var.network.subnets
  nat_instance = var.network.nat_instance
  bastion = var.network.bastion
  session_manager_policy = module.ssm.session_manager_policy
  multi_az = var.network.multi_az
}

module "tooling" {
  source  = "../../modules/tooling"
  tf      = local.tf
  vpc     = module.network.vpc
  subnet = module.network.subnet-tooling
  instance = var.tooling.instance
  session_manager_policy = module.ssm.session_manager_policy
}

module "rds_main" {
  source            = "../../modules/rds/main"
  tf                = local.tf
  administrator_role_arn = var.administrator_role_arn
  vpc     = module.network.vpc
  subnet_ids = module.network.subnet-database-ids
  allowed_security_group_ids = concat(var.rds.main.allowed_security_group_ids, [
    module.ecs_service_api_main.security_group_id
  ])
  ssm = {
    parameters = var.rds.main.ssm_parameters
    kms_key_id = module.ssm.kms_key.id
  }
  db_instance = var.rds.main.db_instance
  alarm = var.rds.main.alarm
}

module "acm" {
  source = "../../modules/acm"
  tf = local.tf
  hostedzone_id   = var.hostedzone_id
  domain          = var.domain
}

module "ingress_common_public" {
  source = "../../modules/ingress/common_public"
  tf                = local.tf
  vpc     = module.network.vpc
  subnet = {
    ids = module.network.subnet-public-ids
  }
  hostedzone_id   = var.hostedzone_id
  domain          = var.domain
  fqdn = {
    app_community = local.fqdn.app_community
  }
  targets = {
    api_main = {
      port = var.ecs_services.api_main.container.port
      health_check_path = var.ecs_services.api_main.health_check_pach
    }
    app_community = {
      port = var.ecs_services.app_community.container.port
      health_check_path = var.ecs_services.app_community.health_check_pach
    }
  }
  certificate_arn = module.acm.current_region_certificate_arn
  cognito = {
    user_pool_arn = module.cognito_user.user_pool_arn
    user_pool_client_id = module.cognito_user.community_user_pool_client_id
    user_pool_domain = module.cognito_user.community_user_pool_domain
  }
  logging_bucket = module.logging_bucket.bucket
  logging_bucket_prefix = module.logging_bucket.prefix_alb
}

resource "aws_service_discovery_private_dns_namespace" "private_dns" {
  name = var.service_discovery_namespace
  vpc  = module.network.vpc.id
}

module "ecr" {
  source                 = "../../modules/ecr"
  tf                     = local.tf
  administrator_role_arn = var.administrator_role_arn
  deploy_role_arn        = module.deploy_role.role_arn
  ecr_repositories       = var.ecr_repositories
}

resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster.name
  capacity_providers = var.ecs_cluster.capacity_providers
}

module "ecs_service_api_main" {
  source = "../../modules/ecs_services/api_main"
  tf = local.tf
  service = {
    name = "api-main"
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
  desired_count = var.ecs_services.api_main.desired_count
  load_balancer = {
    security_group_id = module.ingress_common_public.security_group_id
    target_group_arn = module.ingress_common_public.target_group_api_main_arn
    container = var.ecs_services.api_main.container
  }
  ecs_cluster = {
    arn  = aws_ecs_cluster.cluster.arn
    name = aws_ecs_cluster.cluster.name
  }
  ecs_task_definition = var.ecs_services.api_main.ecs_task_definition
  ecs_service = {
    capacity_provider_strategy = {
      capacity_provider = var.ecs_services.api_main.capacity_provider_strategy.capacity_provider
      weight = var.ecs_services.api_main.capacity_provider_strategy.weight 
    }
  }
  allow_ssm_parameter_paths = [
    "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/rds/main/develop/*"
  ]
  kms_key_ids = {
    ssm = module.ssm.kms_key.id
  }
  service_discovery = {
    private_dns_namespace_id = aws_service_discovery_private_dns_namespace.private_dns.id
  }
  alarm_thresholds = var.ecs_services.api_main.alarm_thresholds
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
  ecs_service = {
    capacity_provider_strategy = {
      capacity_provider = var.ecs_services.app_community.capacity_provider_strategy.capacity_provider
      weight = var.ecs_services.app_community.capacity_provider_strategy.weight 
    }
  }
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

module "deploy_role" {
  source = "../../modules/deploy_role"
  tf     = local.tf
  github = var.github
  roles_for_pass_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.ecs_service_api_main.task-role.name}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.ecs_service_api_main.task-execution-role.name}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.ecs_service_app_community.task-role.name}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.ecs_service_app_community.task-execution-role.name}"
  ]
  ecs_service_arns = [
    "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster.name}/api-main",
    "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster.name}/app-community"
  ]
}

module "cognito_user" {
  source = "../../modules/cognito/user"
  tf     = local.tf
  callback_urls = [
    "https://${local.fqdn.app_community}",
    "https://${local.fqdn.app_community}/oauth2/idpresponse"
  ]
  user_pool_domain = var.cognito.user.user_pool_domain
}
