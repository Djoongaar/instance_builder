variable "zone_a" { type = string }
variable "zone_b" { type = string }
variable "zone_c" { type = string }
variable "vpc_cidr" { type = string }
variable "vpc_cidr_zone_a" { type = string }
variable "vpc_cidr_zone_b" { type = string }
variable "vpc_cidr_zone_c" { type = string }


resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "default"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_zone_a
  availability_zone = var.zone_a

  tags = {
    Name = "Subnet A"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_zone_b
  availability_zone = var.zone_b

  tags = {
    Name = "Subnet B"
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_zone_c
  availability_zone = var.zone_c

  tags = {
    Name = "Subnet C"
  }
}

resource "aws_security_group" "locals_only" {
  name        = "Local access only"
  description = "Allow only local TCP and ICMP traffic"

  vpc_id = aws_vpc.main.id

  #   SSH only under VPN
  ingress {
    cidr_blocks = [aws_vpc.main.cidr_block]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  #   LDAP only under VPN
  ingress {
    cidr_blocks = [aws_vpc.main.cidr_block]
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
  }
  #   ICMP only under VPN
  ingress {
    cidr_blocks = [aws_vpc.main.cidr_block]
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Local access only"
  }
}

resource "aws_security_group" "ssh_and_vpn" {
  name        = "SSH and VPN allowed only"
  description = "Allow only SSH and OpenVPN traffic from everywhere and ICMP traffic only for local instances"

  vpc_id = aws_vpc.main.id

  #   VPN server available from everywhere
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
  }
  #   SSH only under VPN
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  #   ICMP also under VPN
  ingress {
    cidr_blocks = [aws_vpc.main.cidr_block]
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH and VPN allowed only"
  }
}

output "vpc_id" {
  description = "ID of the Virtual Private Cloud"
  value       = aws_vpc.main.id
}

output "sg_ssh_and_vpn" {
  description = "SSH and VPN security group name"
  value       = aws_security_group.ssh_and_vpn.id
}

output "sg_locals_only" {
  description = "Local access only security group name"
  value       = aws_security_group.locals_only.id
}

output "subnet_a_id" {
  description = "AWS Subnet A id"
  value       = aws_subnet.subnet_a.id
}

output "subnet_b_id" {
  description = "AWS Subnet B id"
  value       = aws_subnet.subnet_b.id
}

output "subnet_c_id" {
  description = "AWS Subnet C id"
  value       = aws_subnet.subnet_c.id
}