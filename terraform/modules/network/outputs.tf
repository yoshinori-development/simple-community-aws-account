output "vpc" {
  value = aws_vpc.service
}

output "subnet-public-a" {
  value = aws_subnet.public-a
}

output "subnet-public-c" {
  value = aws_subnet.public-c
}

output "subnet-public-ids" {
  value = [
    aws_subnet.public-a.id,
    aws_subnet.public-c.id
  ]
}

output "subnet-application-a" {
  value = aws_subnet.application-a
}

output "subnet-application-c" {
  value = aws_subnet.application-c
}

output "subnet-application-ids" {
  value = [
    aws_subnet.application-a.id,
    aws_subnet.application-c.id
  ]
}

output "subnet-database-a" {
  value = aws_subnet.database-a
}

output "subnet-database-c" {
  value = aws_subnet.database-c
}

output "subnet-database-ids" {
  value = [
    aws_subnet.database-a.id,
    aws_subnet.database-c.id
  ]
}

output "subnet-tooling" {
  value = aws_subnet.tooling
}

output "bastion_security_group" {
  value = aws_security_group.bastion
}

output "bastion_instance_role" {
  value = aws_iam_role.bastion
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "nat_instance_role" {
  value = aws_iam_role.nat
}

output "nat_instance_a_id" {
  value = aws_instance.nat-a.id
}

output "nat_instance_c_id" {
  value = var.multi_az ? aws_instance.nat-c[0].id : null
}