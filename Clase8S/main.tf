terraform {
 required_version = ">=0.12"
 required_providers {
   aws = {
     source = "hashicorp/aws"
     version = "~> 5.0.0"
   }
 }
}


provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  region = var.zona
}

data "aws_ami" "ami_ec2" {
  most_recent = true

  owners = ["099720109477"] 
  virtualization_type = "hvm"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.resource_name
  cidr = "10.0.0.0/16"

  azs = ["${var.zona}a", "${var.zona}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  create_database_subnet_group = true
  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "allow_ssh_pub" {
  name = "ssh-pub-${var.resource_name}"
  description = "Grupo de seguridad"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh_priv" {
  name = "ssh-priv-${var.resource_name}"
  description = "Grupo de seguridad"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2Cl9G3Priv" {
  ami = data.aws_ami.ami_ec2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh_priv.id]
  subnet_id = module.vpc.private_subnets[0]
}

resource "aws_instance" "ec2Cl9G3Pub" {
  ami = data.aws_ami.ami_ec2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh_pub.id]
  subnet_id = module.vpc.public_subnets[0]
}