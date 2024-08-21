variable "ami" { type = string }
variable "vpc_id" { type = string }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "tls_private_key" "ldap_id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ldap_server_key" {
  key_name   = "ldap_server_key"
  public_key = tls_private_key.ldap_id_rsa.public_key_openssh
}

resource "aws_security_group" "locals_only" {
  name        = "locals_only"
  description = "Allow only local TCP and ICMP traffic"

  vpc_id = data.aws_vpc.main.id

  #   SSH only under VPN
  ingress {
    cidr_blocks = ["172.31.32.0/20"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  #   ICMP only under VPN
  ingress {
    cidr_blocks = ["172.31.32.0/20"]
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
    Name = "locals_only"
  }
}

resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ldap_server_key.key_name
  associate_public_ip_address = false
  security_groups             = [aws_security_group.locals_only.name]

  root_block_device {
    volume_size = 20
    volume_type = "standard"
  }

  tags = {
    Name = "ldapServer"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "instance_private_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.server.private_ip
}

resource "local_file" "private_key" {
  content  = tls_private_key.ldap_id_rsa.private_key_openssh
  filename = ".ssh/id_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ldap_id_rsa.public_key_openssh
  filename = ".ssh/id_rsa.pub"
}