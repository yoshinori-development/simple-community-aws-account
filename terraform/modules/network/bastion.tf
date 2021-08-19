data "aws_ami" "bastion" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = [var.bastion.ami_name_filter]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.bastion.image_id
  instance_type = var.bastion.instance_type
  subnet_id     = aws_subnet.tooling.id
  iam_instance_profile = aws_iam_instance_profile.bastion.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.bastion.key_name
  tags = {
    Name = "bastion"
    AllowSessionManger = true
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.tf.fullname}-bastion"
  public_key = file("./key_pairs/bastion.pub")
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.tf.fullname}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "${var.tf.fullname}-bastion"
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

resource "aws_iam_role_policy_attachment" "bastion_attach_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_attach_session_manager_policy" {
  role       = aws_iam_role.bastion.name
  policy_arn = var.session_manager_policy.arn
}

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "bastion security group"
  vpc_id      = aws_vpc.service.id
  tags = {
    Name = "bastion"
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