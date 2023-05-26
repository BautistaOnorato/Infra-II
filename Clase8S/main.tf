provider "aws" {
  shared_credentials_files = ["~/.aws/credentials" ]
  region = var.zona
}

data "aws_ami" "ami_ec2" {
  most_recent = true

  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.resource_name
  cidr = "10.0.0.0/16"

  azs = ["sa-east-1a", "sa-east-1b"]
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
  subnet_id = "10.0.1.0/24"
}

resource "aws_instance" "ec2Cl9G3Pub" {
  ami = data.aws_ami.ami_ec2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh_pub.id]
  subnet_id = "10.0.0.101/24"
}