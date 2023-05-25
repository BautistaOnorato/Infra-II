provider "aws" {
  shared_credentials_files = "~/.aws/credentilas" 
  region = "sa-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpcc8c4b"
  cidr = "10.0.0.0/16"

  azs = ["sa-east-1a", "sa-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name = "ec2c8c4b"
  instance_count = 1

  ami = "ami-0af6e9042ea5a4e3e"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.ssh_security_group.this_security_group_id]
  subnet_ids = module.vpc.private_subnets
}

module "ssh_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"
  version = "~> 3.0"

  name = "ssh-server-c8c4b"
    description = "Grupo de seguridad"
    vpc_id = module.vpc.vpc_id

    ingress_cidr_blocks = ["10.10.0.0/16"]
}