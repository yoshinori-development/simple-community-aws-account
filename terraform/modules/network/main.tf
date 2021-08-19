data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_vpc" "service" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.tf.fullname
  }
}

# --- public subnet ---
resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = var.subnets.public.a.cidr_block
  tags = {
    Name = "${var.tf.fullname}-public-a"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}c"
  cidr_block        = var.subnets.public.c.cidr_block
  tags = {
    Name = "${var.tf.fullname}-public-c"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.service.id
  tags = {
    Name = "${var.tf.fullname}-public"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-c" {
  subnet_id      = aws_subnet.public-c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.service.id
}

# --- application subnet ---
resource "aws_subnet" "application-a" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = var.subnets.application.a.cidr_block
  tags = {
    Name = "${var.tf.fullname}-application-a"
  }
}

resource "aws_subnet" "application-c" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}c"
  cidr_block        = var.subnets.application.c.cidr_block
  tags = {
    Name = "${var.tf.fullname}-application-c"
  }
}

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.service.id
  tags = {
    Name = "${var.tf.fullname}-application"
  }

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat-a.id
  }
}

resource "aws_route_table_association" "application-a" {
  subnet_id      = aws_subnet.application-a.id
  route_table_id = aws_route_table.application.id
}

resource "aws_route_table_association" "application-c" {
  subnet_id      = aws_subnet.application-c.id
  route_table_id = aws_route_table.application.id
}


# --- database subnet ---
resource "aws_subnet" "database-a" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = var.subnets.database.a.cidr_block
  tags = {
    Name = "${var.tf.fullname}-database-a"
  }
}

resource "aws_subnet" "database-c" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}c"
  cidr_block        = var.subnets.database.c.cidr_block
  tags = {
    Name = "${var.tf.fullname}-database-c"
  }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.service.id
  tags = {
    Name = "${var.tf.fullname}-database"
  }
}

resource "aws_route_table_association" "database-a" {
  subnet_id      = aws_subnet.database-a.id
  route_table_id = aws_route_table.database.id
}

resource "aws_route_table_association" "database-c" {
  subnet_id      = aws_subnet.database-c.id
  route_table_id = aws_route_table.database.id
}

# --- tooling subnet ---
resource "aws_subnet" "tooling" {
  vpc_id            = aws_vpc.service.id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = var.subnets.tooling.cidr_block
  tags = {
    Name = "${var.tf.fullname}-tooling"
  }
}

resource "aws_route_table" "tooling" {
  vpc_id = aws_vpc.service.id
  tags = {
    Name = "${var.tf.fullname}-tooling"
  }

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat-a.id
  }
}

resource "aws_route_table_association" "tooling" {
  subnet_id      = aws_subnet.tooling.id
  route_table_id = aws_route_table.tooling.id
}
