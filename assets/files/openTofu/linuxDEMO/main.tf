terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "ssh_key_path" {
  description = "Path to save the SSH private key"
  type        = string
  default     = "aws-ec2-linux-key.pem"
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "tls_private_key" "linux" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_sensitive_file" "linux_private_key" {
  content  = tls_private_key.linux.private_key_pem
  filename = var.ssh_key_path
}
resource "aws_key_pair" "linux" {
  key_name   = "aws-ec2-linux-key"
  public_key = tls_private_key.linux.public_key_openssh
}

resource "aws_security_group" "linux_sg" {
  name        = "linux-sg"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For demo; restrict for real use!
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "linux_ec2_ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "linux_ec2_ssm_profile"
  role = aws_iam_role.ssm_role.name
}

data "aws_ami" "al2_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "linux" {
  count                       = 2
  ami                         = data.aws_ami.al2_latest.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[count.index]
  vpc_security_group_ids      = [aws_security_group.linux_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true
  key_name                    = aws_key_pair.linux.key_name

  # SSM agent is preinstalled and enabled on AL2,
  # but let's make sure it's running and up-to-date.
  user_data = <<-EOF
    #!/bin/bash
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "al2-demo-${count.index + 1}"
  }
}

output "linux_instance_table" {
  description = "EC2 instance details (ID, Public IP, Name tag)"
  value = [
    for i in aws_instance.linux :
    {
      id        = i.id
      public_ip = i.public_ip
      name      = i.tags["Name"]
    }
  ]
}

output "key_pair_name" {
  value       = aws_key_pair.linux.key_name
  description = "AWS EC2 key pair name"
}
output "private_key_path" {
  value       = var.ssh_key_path
  description = "Path to the generated EC2 SSH private key"
}