variable "instance_name" { type = string }
variable "instance_type" { type = string }
variable "zone" { type = string }
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

provider "aws" {
  region = var.zone
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow only SSH traffic"

  vpc_id = data.aws_vpc.main.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "openssh_key" {
  key_name   = "openssh_key"
  public_key = tls_private_key.id_rsa.public_key_openssh
}

resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.openssh_key.key_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.allow_ssh.name]

  root_block_device {
    volume_size = 20
    volume_type = "standard"
  }

  tags = {
    Name = var.instance_name
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "public_key" {
  description = "Public key to OpenSSH"
  value       = tls_private_key.id_rsa.public_key_openssh
}

output "private_key" {
  description = "Private key to OpenSSH"
  value       = tls_private_key.id_rsa.private_key_openssh
  sensitive   = true
}

resource "local_file" "private_key" {
  content  = tls_private_key.id_rsa.private_key_openssh
  filename = ".ssh/id_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.id_rsa.public_key_openssh
  filename = ".ssh/id_rsa.pub"
}