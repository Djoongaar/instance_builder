variable "vpc_id" { type = string }


data "aws_vpc" "default" {
  id = var.vpc_id
}


resource "aws_security_group" "locals_only" {
  name        = "Local access only"
  description = "Allow only local TCP and ICMP traffic"

  vpc_id = data.aws_vpc.default.id

  #   SSH only under VPN
  ingress {
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  #   LDAP only under VPN
  ingress {
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
  }
  #   ICMP only under VPN
  ingress {
    cidr_blocks = [data.aws_vpc.default.cidr_block]
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

  vpc_id = data.aws_vpc.default.id

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
    cidr_blocks = ["0.0.0.0/0"]
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

data "aws_subnet" "subnet_a" {
  id = "subnet-06d9397a9df4368cc"
}

resource "aws_network_interface" "vpn_interface" {
  subnet_id       = data.aws_subnet.subnet_a.id
  security_groups = [aws_security_group.ssh_and_vpn.id]
}

resource "aws_eip" "my_public_ip" {
  network_interface = aws_network_interface.vpn_interface.id
}

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn_server_key" {
  key_name   = "openssh_key"
  public_key = tls_private_key.id_rsa.public_key_openssh
}

output "vpn_interface_id" {
  description = "Network interface for VPN Server"
  value       = aws_network_interface.vpn_interface.id
}

output "ssh_key_name" {
  description = "SSH key pair"
  value       = aws_key_pair.vpn_server_key.key_name
}

resource "local_file" "private_key" {
  content  = tls_private_key.id_rsa.private_key_openssh
  filename = ".ssh/id_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.id_rsa.public_key_openssh
  filename = ".ssh/id_rsa.pub"
}