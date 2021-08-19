data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  alb_name = "${var.tf.fullname}-common"
}

resource "aws_lb" "common-public" {
  name                       = local.alb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.common-public.id]
  subnets                    = var.subnet.ids
  enable_deletion_protection = false # TODO: 本稼働時はtrueにする

  access_logs {
    bucket  = var.logging_bucket.id
    prefix  = var.logging_bucket_prefix
    enabled = true
  }
}

resource "aws_security_group" "common-public" {
  name        = local.alb_name
  description = local.alb_name
  vpc_id      = var.vpc.id

  ingress {
    description = "http (for redirect)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https production"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "common-public-redirect" {
  load_balancer_arn = aws_lb.common-public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
    }
  }
}

resource "aws_lb_listener" "common-public-listener" {
  load_balancer_arn = aws_lb.common-public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  lifecycle {
    ignore_changes = [default_action]
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.common-public-app-community.arn
  }
}

resource "aws_lb_listener_rule" "common-public-forward-app-community" {
  listener_arn = aws_lb_listener.common-public-listener.arn
  priority     = 100

  # action {
  #   type = "authenticate-cognito"
  #   authenticate_cognito {
  #     scope                      = "openid email"
  #     on_unauthenticated_request = "authenticate"
  #     # session_timeout = 100000
  #     user_pool_arn       = var.auth_console.user_pool_arn
  #     user_pool_client_id = var.auth_console.user_pool_client_id
  #     user_pool_domain    = var.auth_console.user_pool_domain
  #   }
  # }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.common-public-app-community.arn
  }

  condition {
    host_header {
      values = [
        var.hosts.app_community == "" ? var.domain : "${var.hosts.app_community}.${var.domain}"
      ]
    }
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb_listener_rule" "common-public-forward-api-core" {
  listener_arn = aws_lb_listener.common-public-listener.arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.common-public-api-core.arn
  }

  condition {
    host_header {
      values = [
        var.hosts.app_community == "" ? var.domain : "${var.hosts.app_community}.${var.domain}"
      ]
    }
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_target_group" "common-public-app-community" {
  name        = "${var.tf.fullshortname}-app-community"
  port        = var.targets.app_community.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc.id
  health_check {
    path = var.targets.app_community.health_check_path
    port = var.targets.app_community.port
  }
}

resource "aws_lb_target_group" "common-public-api-core" {
  name        = "${var.tf.fullshortname}-api-core"
  port        = var.targets.api_core.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc.id
  health_check {
    path = var.targets.api_core.health_check_path
    port = var.targets.api_core.port
  }
}

# Route53
# resource "aws_route53_record" "common-public-a-record" {
#   zone_id = var.hostedzone_id
#   name    = var.hosts.app_community == "" ? var.domain : "${var.hosts.app_community}.${var.domain}"
#   type    = "A"

#   alias {
#     name                   = aws_lb.common-public.dns_name
#     zone_id                = aws_lb.common-public.zone_id
#     evaluate_target_health = true
#   }
# }

