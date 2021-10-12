data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_openid_connect_provider" "github_deployment" {
  url = var.github.id_provider.url
  client_id_list = var.github.id_provider.client_id_list 
  thumbprint_list = var.github.id_provider.thumbprint_list
}

resource "aws_iam_role" "github_deployment" {
  name = "github_deployment_${var.tf.env}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": "${aws_iam_openid_connect_provider.github_deployment.arn}"
        },
        "Effect": "Allow",
        "Condition": {
          "StringLike": {
            "vstoken.actions.githubusercontent.com:sub": "repo:${var.github.organization}/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_deployment" {
  role       = aws_iam_role.github_deployment.name
  policy_arn = aws_iam_policy.github_deployment.arn
}

resource "aws_iam_policy" "github_deployment" {
  name = "github_deployment_${var.tf.env}"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
         "Effect":"Allow",
         "Action":[
            "sts:GetCallerIdentity"
         ],
         "Resource":["*"]
      },
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
      },
      {
         "Sid":"RegisterTaskDefinition",
         "Effect":"Allow",
         "Action":[
            "ecs:RegisterTaskDefinition"
         ],
         "Resource":"*"
      },
      {
         "Sid":"PassRolesInTaskDefinition",
         "Effect":"Allow",
         "Action":[
            "iam:PassRole"
         ],
         "Resource": "${var.roles_for_pass_role_arns}"
      },
      {
         "Sid":"DeployService",
         "Effect":"Allow",
         "Action":[
            "ecs:UpdateService",
            "ecs:DescribeServices"
         ],
         "Resource": "${var.ecs_service_arns}"
      }
    ]
  })
}
