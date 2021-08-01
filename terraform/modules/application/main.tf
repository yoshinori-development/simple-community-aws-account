module "ecr" {
  source = "../../modules/application/ecr"
  tf = var.tf
  administrator_role_arn = var.administrator_role_arn
  deploy_user_arn = aws_iam_user.github_deployer.arn
  ecr_repositories = var.ecr_repositories
}

# resource "aws_ecs_cluster" "cluster" {
#   name = var.ecs_cluster.name
#   capacity_providers = ["FARGATE"]
# }

# module "ingress" {
#   source = "../../modules/ingress"

#   infra = var.infra
#   vpc = {
#     id = module.network.vpc_id
#   }
#   public_subnet = {
#     ids = module.network.public_subnet_ids
#     cidr_blocks = module.network.public_subnet_cidr_blocks
#   }
#   hostedzone_id   = var.hostedzone_id
#   domain          = var.domain
#   hosts = {
#     tracker = var.hosts.app_tracker.develop
#     console = var.hosts.app_console.develop
#   }
#   certificate_arn = var.certificate_arn
#   auth_console = {
#     user_pool_arn = module.auth_console.aws_cognito_user_pool_arn
#     user_pool_client_id = module.auth_console.aws_cognito_user_pool_client_id
#     user_pool_domain = module.auth_console.aws_cognito_user_pool_domain
#   }
# }

# resource "aws_service_discovery_private_dns_namespace" "private_dns" {
#   name = var.service_discovery.name
#   vpc  = module.network.vpc_id
# }


# module "api-core" {
#   source = "../../modules/services/api-core"

#   infra = var.infra
#   service = {
#     name = "api-core"
#     shortname = "ac"
#     env  = "develop"
#   }

#   vpc = {
#     id = module.network.vpc_id
#   }
#   private_subnet = {
#     ids   = module.network.private_subnet_ids
#     cidr_blocks = module.network.private_subnet_cidr_blocks
#   }
#   alb_security_group_id = module.ingress.security_group_id
#   ecs_cluster = {
#     arn  = aws_ecs_cluster.cluster.arn
#     name = aws_ecs_cluster.cluster.name
#   }
#   target_group_arn = module.ingress.target_group_api_core_arn
#   service_discovery = {
#     private_dns_namespace_id = aws_service_discovery_private_dns_namespace.private_dns.id
#   }
#   container = {
#     name = "nginx"
#     port = 8000
#   }
#   ssm_parameter_prefix = "parameter/${var.infra.name}/${var.infra.env}/*"
#   kms_key_id = var.kms_key_id.rds
#   alarm_threshold = {
#     cpu_utilization = "80"
#     memory_utilization = "80"
#   }
#   sns_topic_arn = module.metrics_notify_slack.this_slack_topic_arn
# }


# module "app-tracker-develop" {
#   source = "../../modules/services/app-tracker"

#   infra = var.infra
#   service = {
#     name = "app-tracker"
#     shortname = "at"
#     env  = "develop"
#   }

#   vpc = {
#     id = module.network.vpc_id
#   }
#   private_subnet = {
#     ids = module.network.private_subnet_ids
#     cidr_blocks = module.network.private_subnet_cidr_blocks
#   }
#   alb_security_group_id = module.ingress.security_group_id
#   ecs_cluster = {
#     arn  = aws_ecs_cluster.cluster.arn
#     name = aws_ecs_cluster.cluster.name
#   }
#   target_group_arn = module.ingress.target_group_app_tracker_arn
#   container = {
#     name = "nginx"
#     port = 80
#   }
#   alarm_threshold = {
#     cpu_utilization = "80"
#     memory_utilization = "80"
#   }
#   sns_topic_arn = module.metrics_notify_slack.this_slack_topic_arn
# }

# module "app-console" {
#   source = "../../modules/services/app-console"

#   infra = var.infra
#   service = {
#     name = "app-console"
#     shortname = "ac"
#     env  = "develop"
#   }

#   vpc = {
#     id = module.network.vpc_id
#   }
#   private_subnet = {
#     ids = module.network.private_subnet_ids
#     cidr_blocks = module.network.private_subnet_cidr_blocks
#   }
#   alb_security_group_id = module.ingress.security_group_id
#   ecs_cluster = {
#     arn  = aws_ecs_cluster.cluster.arn
#     name = aws_ecs_cluster.cluster.name
#   }
#   target_group_arn = module.ingress.target_group_app_console_arn
#   container = {
#     name = "nginx"
#     port = 80
#   }
#   alarm_threshold = {
#     cpu_utilization = "80"
#     memory_utilization = "80"
#   }
#   sns_topic_arn = module.metrics_notify_slack.this_slack_topic_arn
# }


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