variable "ami" { type = string }
variable "vpc_id" { type = string }
variable "vpn_subnet_id" { type = string }
variable "sg_ssh_and_vpn" { type = string }
variable "vpn_private_ip" { type = string }


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

data "aws_subnet" "subnet_a" {
  vpc_id = data.aws_vpc.main.id
  id     = var.vpn_subnet_id
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.server.id
}

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn_server_key" {
  key_name   = "openssh_key"
  public_key = tls_private_key.id_rsa.public_key_openssh
}

resource "aws_network_interface" "main" {
  subnet_id       = data.aws_subnet.subnet_a.id
  private_ips     = [var.vpn_private_ip]
  security_groups = [var.sg_ssh_and_vpn]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "server" {
  ami           = var.ami
  instance_type = "t2.micro"
  key_name      = aws_key_pair.vpn_server_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 20
    volume_type = "standard"
  }

  tags = {
    Name = "openVpnServer"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.my_static_ip.public_ip
}

output "instance_private_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.my_static_ip.private_ip
}

resource "local_file" "private_key" {
  content  = tls_private_key.id_rsa.private_key_openssh
  filename = ".ssh/id_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.id_rsa.public_key_openssh
  filename = ".ssh/id_rsa.pub"
}