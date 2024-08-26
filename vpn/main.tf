variable "ami" { type = string }
variable "vpc_id" { type = string }
variable "zone_a" { type = string }
variable "ssh_key_name" { type = string }
variable "vpn_interface_id" { type = string }


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_key_pair" "vpn_keypair" {
  key_name = var.ssh_key_name
}

resource "aws_instance" "server" {
  ami               = var.ami
  instance_type     = "t2.micro"
  key_name          = var.ssh_key_name
  availability_zone = var.zone_a

  network_interface {
    network_interface_id = var.vpn_interface_id
    device_index         = 0
  }

  root_block_device {
    volume_size = 20
    volume_type = "standard"
  }

  tags = {
    Name = "openVPN"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.server.private_ip
}

output "public_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.server.public_ip
}