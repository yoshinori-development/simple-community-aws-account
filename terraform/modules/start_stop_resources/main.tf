data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "stop-resources" {
  name        = "${var.tf.fullname}-stop-resources"
  description = "Stop resources for development"
  schedule_expression = "cron(0 15 * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop-resources" {
  arn       = aws_lambda_function.stop-resources.arn
  rule      = aws_cloudwatch_event_rule.stop-resources.id
  target_id = "StopResources"
}

resource "aws_iam_role" "start-stop-resources" {
  name        = "${var.tf.fullname}-start-stop-resources-function"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "start-stop-resources" {
  name        = "${var.tf.fullname}-start-stop-resources-function"
  description = "${var.tf.fullname} start stop resources function"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Resource": [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/${var.ec2_nat_id}",
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/${var.ec2_bastion_id}",
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/${var.ec2_tooling_id}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:StartDBInstance",
        "rds:StopDBInstance",
        "rds:DescribeDBInstances"
      ],
      "Resource": [
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${var.rds_main_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService"
      ],
      "Resource": [
        "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_api_main_name}",
        "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_app_community_name}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "start-stop-resources" {
  role       = aws_iam_role.start-stop-resources.name
  policy_arn = aws_iam_policy.start-stop-resources.arn
}

data "archive_file" "start-stop-resources" {
  type        = "zip"
  source_dir  = "../../modules/start_stop_resources/function/"
  output_path = "archives/${var.tf.fullname}-start-stop-resources-function.zip"
}

resource "aws_lambda_function" "stop-resources" {
  function_name = "${var.tf.fullname}-stop-resources-function"
  role          = aws_iam_role.start-stop-resources.arn
  filename      = data.archive_file.start-stop-resources.output_path   
  handler       = "index.stopResources"
  runtime       = "nodejs14.x"
  timeout       = 15
  source_code_hash = data.archive_file.start-stop-resources.output_base64sha256
  publish = true
  environment {
    variables = {
      EC2_TOOLING_ID = var.ec2_tooling_id
      EC2_NAT_ID = var.ec2_nat_id
      EC2_BASTION_ID = var.ec2_bastion_id
      RDS_CORE_ID = var.rds_main_id
      ECS_CLUSTER_NAME = var.ecs_cluster_name
      ECS_SERVICES_API_CORE_NAME = var.ecs_service_api_main_name
      ECS_SERVICES_APP_COMMUNITY_NAME = var.ecs_service_app_community_name
    }
  }
}

resource "aws_lambda_function" "start-resources" {
  function_name = "${var.tf.fullname}-start-resources-function"
  role          = aws_iam_role.start-stop-resources.arn
  filename      = data.archive_file.start-stop-resources.output_path   
  handler       = "index.startResources"
  runtime       = "nodejs14.x"
  timeout       = 15
  source_code_hash = data.archive_file.start-stop-resources.output_base64sha256
  publish = true
  environment {
    variables = {
      EC2_NAT_ID = var.ec2_nat_id
      EC2_BASTION_ID = var.ec2_bastion_id
      RDS_CORE_ID = var.rds_main_id
      ECS_CLUSTER_NAME = var.ecs_cluster_name
      ECS_SERVICES_API_CORE_NAME = var.ecs_service_api_main_name
      ECS_SERVICES_APP_COMMUNITY_NAME = var.ecs_service_app_community_name
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBrigde"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop-resources.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop-resources.arn
}