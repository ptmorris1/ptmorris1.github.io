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

# Specify path to save the private key; override with -var if desired
variable "ssh_key_path" {
  description = "Path to save the SSH private key"
  type        = string
  default     = "aws-ec2-key.pem" # saves in current directory by default
}

# Generate SSH key pair for EC2
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ec2_private_key" {
  content  = tls_private_key.ec2.private_key_pem
  filename = var.ssh_key_path
}

resource "aws_key_pair" "ec2" {
  key_name   = "aws-ec2-key"
  public_key = tls_private_key.ec2.public_key_openssh
}

# Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# IAM Role and Instance Profile for SSM
resource "aws_iam_role" "ssm_role" {
  name = "ec2_ssm_role"
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
  name = "ec2_ssm_profile"
  role = aws_iam_role.ssm_role.name
}

# Security group for RDP and SSM
resource "aws_security_group" "win_sg" {
  name        = "windows-sg"
  description = "Allow RDP and SSM"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For testing only! Restrict for production.
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get latest Windows 2022 AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Launch Windows EC2 instance
resource "aws_instance" "win_ec2" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.win_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ec2.key_name

  root_block_device {
    volume_size = 30 # Required minimum for Windows AMIs
    volume_type = "gp3"
  }
  tags = {
    Name = "demo"
  }
}

output "windows_instance_public_ip" {
  value       = aws_instance.win_ec2.public_ip
  description = "Public IP address of the Windows EC2 instance"
}

output "key_pair_name" {
  value       = aws_key_pair.ec2.key_name
  description = "AWS EC2 key pair name"
}

output "private_key_path" {
  value       = var.ssh_key_path
  description = "Path to the generated EC2 SSH private key"
}