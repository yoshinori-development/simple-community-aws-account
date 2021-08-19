data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ecs_task_definition" "default" {
  task_definition = local.fullname
}

resource "aws_ecs_service" "default" {
  name            = local.service.fullname
  cluster         = var.ecs_cluster.arn
  task_definition = "${data.aws_ecs_task_definition.default.family}:${data.aws_ecs_task_definition.default.revision}"
  desired_count   = var.desired_count
  platform_version = "1.4.0"
  propagate_tags   = "SERVICE"
  health_check_grace_period_seconds = 120

  deployment_controller {
    type = "ECS"
  }

  capacity_provider_strategy {
    capacity_provider = var.ecs_service.capacity_provider_strategy.capacity_provider
    weight = var.ecs_service.capacity_provider_strategy.weight
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      load_balancer,
      platform_version,
    ]
  }

  network_configuration {
    subnets          = var.subnet.ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.load_balancer.target_group_arn
    container_name   = var.load_balancer.container.name
    container_port   = var.load_balancer.container.port
  }
}

resource "aws_cloudwatch_log_group" "default" {
  name = "/aws/ecs/${local.fullname}"
}

resource "aws_security_group" "ecs_service" {
  name        = local.fullname
  description = local.fullname
  vpc_id      = var.vpc.id

  ingress {
    description     = "from alb"
    from_port       = var.load_balancer.container.port
    to_port         = var.load_balancer.container.port
    protocol        = "tcp"
    security_groups = [var.load_balancer.security_group_id]
  }

  ingress {
    description = "from private subnet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.subnet.cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Task Role
resource "aws_iam_role" "task-role" {
  name               = "${local.fullname}-task-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Task Policyが必要になったらここに記述
# resource "aws_iam_policy" "task-policy" {
#   name        = "${local.fullname}-policy"
#   description = "${local.fullname} policy"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "task-policy-attach" {
#   role       = aws_iam_role.task-role.name
#   policy_arn = aws_iam_policy.task-policy.arn
# }

## Task Ececution Role
resource "aws_iam_role" "task-execution-role" {
  name               = "${local.fullname}-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Execution Policyが必要になったらここに記述
# resource "aws_iam_policy" "task-execution-policy" {
#   name        = "${local.fullname}-execution-policy"
#   description = "${local.fullname} execution policy"
# 
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }
# 
# resource "aws_iam_role_policy_attachment" "task-execution-policy-attach" {
#   role       = aws_iam_role.task-execution-role.name
#   policy_arn = aws_iam_policy.task-execution-policy.arn
# }


# Cloudwatch Metric Alerms
# resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high" {
#   alarm_name          = "${local.infra_fullname}_${local.service_fullname}_cpu_utilization_too_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = var.alarm_threshold.cpu_utilization
#   alarm_description   = "Average database CPU utilization too high"
#   alarm_actions       = [var.sns_topic_arn]
#   ok_actions          = [var.sns_topic_arn]

#   dimensions = {
#     ClusterName = var.ecs_cluster.name
#     ServiceName = local.service_fullname
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "memory_utilization_too_high" {
#   alarm_name          = "${local.infra_fullname}_${local.service_fullname}_memory_utilization_too_high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "MemoryUtilization"
#   namespace           = "AWS/ECS"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = var.alarm_threshold.memory_utilization
#   alarm_description   = "Average database Memory utilization too high"
#   alarm_actions       = [var.sns_topic_arn]
#   ok_actions          = [var.sns_topic_arn]

#   dimensions = {
#     ClusterName = var.ecs_cluster.name
#     ServiceName = local.service_fullname
#   }
# }
