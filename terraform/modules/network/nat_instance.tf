resource "aws_instance" "nat-a" {
  ami                         = var.nat_instance.ami
  instance_type               = var.nat_instance.instance_type
  subnet_id                   = aws_subnet.public-a.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat.id
  vpc_security_group_ids      = [aws_security_group.nat_instance.id]
  key_name                    = aws_key_pair.nat_instance.key_name
  source_dest_check           = false
  tags = {
    Name               = "nat-instance-a"
    AllowSessionManger = true
  }
}

resource "aws_eip" "nat-instance-a" {
  vpc        = true
  instance   = aws_instance.nat-a.id
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "nat-instance-a"
  }
}

resource "aws_instance" "nat-c" {
  count = var.multi_az ? 1 : 0
  ami                         = var.nat_instance.ami
  instance_type               = var.nat_instance.instance_type
  subnet_id                   = aws_subnet.public-c.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat.id
  vpc_security_group_ids      = [aws_security_group.nat_instance.id]
  key_name                    = aws_key_pair.nat_instance.key_name
  source_dest_check           = false
  tags = {
    Name               = "nat-instance-c"
    AllowSessionManger = true
  }
}

resource "aws_eip" "nat-instance-c" {
  count = var.multi_az ? 1 : 0
  vpc        = true
  instance   = aws_instance.nat-c[0].id
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "nat-instance-c"
  }
}

resource "aws_key_pair" "nat_instance" {
  key_name   = "${var.tf.fullname}-nat_instance"
  public_key = file("./key_pairs/nat_instance.pub")
}

resource "aws_iam_instance_profile" "nat" {
  name = "${var.tf.fullname}-nat"
  role = aws_iam_role.nat.name
}

resource "aws_iam_role" "nat" {
  name               = "${var.tf.fullname}-nat_instance"
  path               = "/"
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

resource "aws_iam_role_policy_attachment" "nat_instance_attach_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.nat.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "nat_instance_attach_session_manager_policy" {
  role       = aws_iam_role.nat.name
  policy_arn = var.session_manager_policy.arn
}

resource "aws_security_group" "nat_instance" {
  name        = "nat_instance"
  description = "nat_instance security group"
  vpc_id      = aws_vpc.service.id
  tags = {
    Name = "nat-instance"
  }

  ingress {
    description = "from private subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      aws_subnet.application-a.cidr_block,
      aws_subnet.application-c.cidr_block,
      aws_subnet.tooling.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}