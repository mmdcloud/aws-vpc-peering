# VPC Configuration
module "vpc1" {
  source                = "./modules/vpc/vpc"
  vpc_name              = "vpc1"
  vpc_cidr_block        = "10.1.0.0/24"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "vpc1_igw"
}

# Public Subnets
module "vpc1_subnets" {
  source = "./modules/vpc/subnets"
  name   = "vpc1 public subnet"
  subnets = [
    {
      subnet = "10.1.0.0/28"
      az     = "us-east-1a"
    },
    {
      subnet = "10.1.0.16/28"
      az     = "us-east-1b"
    },
    {
      subnet = "10.1.0.96/28"
      az     = "us-east-1c"
    }
  ]
  vpc_id                  = module.vpc1.vpc_id
  map_public_ip_on_launch = true
}

# Carshub Public Route Table
module "vpc1_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "vpc1 route table"
  subnets = module.vpc1_subnets.subnets[*]
  routes = [
    {
      cidr_block                = "0.0.0.0/0"
      gateway_id                = module.vpc1.igw_id
      nat_gateway_id            = ""
      transit_gateway_id        = ""
      vpc_peering_connection_id = ""
    },
    {
      cidr_block                = "10.2.0.0/24"
      transit_gateway_id        = ""
      gateway_id                = ""
      nat_gateway_id            = ""
      vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_connection.id}"
    }
  ]
  vpc_id = module.vpc1.vpc_id
}

# Security Group
module "vpc1_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc1.vpc_id
  name   = "vpc1-sg"
  ingress = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "vpc2" {
  source                = "./modules/vpc/vpc"
  vpc_name              = "vpc2"
  vpc_cidr_block        = "10.2.0.0/24"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "vpc2_igw"
}

# Public Subnets
module "vpc2_subnets" {
  source = "./modules/vpc/subnets"
  name   = "vpc2 subnet"
  subnets = [
    {
      subnet = "10.2.0.0/28"
      az     = "us-east-1a"
    },
    {
      subnet = "10.2.0.16/28"
      az     = "us-east-1b"
    },
    {
      subnet = "10.2.0.96/28"
      az     = "us-east-1c"
    }
  ]
  vpc_id                  = module.vpc2.vpc_id
  map_public_ip_on_launch = true
}

# Carshub Public Route Table
module "vpc2_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "vpc2 route table"
  subnets = module.vpc2_subnets.subnets[*]
  routes = [
    {
      cidr_block                = "0.0.0.0/0"
      gateway_id                = module.vpc2.igw_id
      nat_gateway_id            = ""
      transit_gateway_id        = ""
      vpc_peering_connection_id = ""
    },
    {
      cidr_block                = "10.1.0.0/24"
      transit_gateway_id        = ""
      gateway_id                = ""
      nat_gateway_id            = ""
      vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_connection.id}"
    }
  ]
  vpc_id = module.vpc2.vpc_id
}

# Security Group
module "vpc2_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc2.vpc_id
  name   = "vpc2-sg"
  ingress = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_key_pair" "key_pair" {
  key_name = "madmaxkeypair"
}

module "instance1" {
  source                      = "./modules/ec2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name        = data.aws_key_pair.key_pair.key_name
  subnet_id       = module.vpc1_subnets.subnets[0].id
  security_groups = [module.vpc1_sg.id]
  user_data       = filebase64("${path.module}/user_data.sh")
  name            = "instance1"

}

module "instance2" {
  source                      = "./modules/ec2"
  name                        = "instance2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name        = data.aws_key_pair.key_pair.key_name
  subnet_id       = module.vpc2_subnets.subnets[0].id
  security_groups = [module.vpc2_sg.id]
  user_data       = filebase64("${path.module}/user_data.sh")
}

## VPC Peering Connection ##
resource "aws_vpc_peering_connection" "peering_connection" {
  peer_vpc_id = module.vpc2.vpc_id
  vpc_id      = module.vpc1.vpc_id
  auto_accept = true

  tags = {
    Name = "VPC-Peering-Connection"
  }
}