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

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.server.id
}

resource "aws_security_group" "ssh_and_vpn" {
  name        = "ssh_and_vpn"
  description = "Allow only SSH and OpenVPN traffic from everywhere and ICMP traffic only for local instances"

  vpc_id = data.aws_vpc.main.id

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
    Name = "ssh_and_vpn"
  }
}

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn_server_key" {
  key_name   = "openssh_key"
  public_key = tls_private_key.id_rsa.public_key_openssh
}

resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.vpn_server_key.key_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ssh_and_vpn.name]

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