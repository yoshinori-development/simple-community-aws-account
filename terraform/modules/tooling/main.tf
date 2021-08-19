data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# data "aws_ami" "tool" {
#   most_recent      = true
#   owners           = ["amazon"]

#   filter {
#     name   = "name"
#     values = [var.instance.ami_name_filter]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

resource "aws_instance" "tool" {
  ami           = var.instance.ami
  instance_type = var.instance.instance_type
  subnet_id     = var.subnet.id
  iam_instance_profile = aws_iam_instance_profile.tool.id
  vpc_security_group_ids = [aws_security_group.tool.id]
  key_name               = aws_key_pair.tool.key_name
  # disable_api_termination = true
  disable_api_termination = false
  tags = {
    Name = "tool"
    AllowSessionManger = true
  }
}

resource "aws_key_pair" "tool" {
  key_name   = "${var.tf.fullname}-tool"
  public_key = file("./key_pairs/tool.pub")
}

resource "aws_iam_instance_profile" "tool" {
  name = "${var.tf.fullname}-tool"
  role = aws_iam_role.tool.name
}

resource "aws_iam_role" "tool" {
  name = "${var.tf.fullname}-tool"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "tool_attach_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.tool.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "tool_attach_session_manager_policy" {
  role       = aws_iam_role.tool.name
  policy_arn = var.session_manager_policy.arn
}

resource "aws_security_group" "tool" {
  name        = "tool"
  description = "tool security group"
  vpc_id      = var.vpc.id
  tags = {
    Name = "tool"
  }

  # ingress {
  #   description = "from private subnet"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = [
  #     aws_subnet.application-a.cidr_block,
  #     aws_subnet.application-c.cidr_block
  #   ]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}