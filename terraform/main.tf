## VPC 1 Resources ##
resource "aws_vpc" "vpc1" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-1"
  }
}

resource "aws_subnet" "vpc1_subnet" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "VPC-1-Subnet"
  }
}

resource "aws_internet_gateway" "vpc1_igw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "VPC-1-IGW"
  }
}

resource "aws_route_table" "vpc1_rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1_igw.id
  }

  route {
    cidr_block                = aws_vpc.vpc2.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "VPC-1-RouteTable"
  }
}

resource "aws_route_table_association" "vpc1_rta" {
  subnet_id      = aws_subnet.vpc1_subnet.id
  route_table_id = aws_route_table.vpc1_rt.id
}

resource "aws_security_group" "vpc1_sg" {
  name        = "vpc1-security-group"
  description = "Allow SSH and ICMP traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPC-1-SecurityGroup"
  }
}

resource "aws_instance" "vpc1_instance" {
  ami                         = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.vpc1_subnet.id
  vpc_security_group_ids      = [aws_security_group.vpc1_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "VPC-1-Instance"
  }
}

## VPC 2 Resources ##
resource "aws_vpc" "vpc2" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-2"
  }
}

resource "aws_subnet" "vpc2_subnet" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "VPC-2-Subnet"
  }
}

resource "aws_internet_gateway" "vpc2_igw" {
  vpc_id = aws_vpc.vpc2.id
  tags = {
    Name = "VPC-2-IGW"
  }
}

resource "aws_route_table" "vpc2_rt" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc2_igw.id
  }

  route {
    cidr_block                = aws_vpc.vpc1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "VPC-2-RouteTable"
  }
}

resource "aws_route_table_association" "vpc2_rta" {
  subnet_id      = aws_subnet.vpc2_subnet.id
  route_table_id = aws_route_table.vpc2_rt.id
}

resource "aws_security_group" "vpc2_sg" {
  name        = "vpc2-security-group"
  description = "Allow SSH and ICMP traffic"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPC-2-SecurityGroup"
  }
}

resource "aws_instance" "vpc2_instance" {
  ami                         = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.vpc2_subnet.id
  vpc_security_group_ids      = [aws_security_group.vpc2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "VPC-2-Instance"
  }
}

## VPC Peering Connection ##
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = aws_vpc.vpc2.id
  vpc_id      = aws_vpc.vpc1.id
  auto_accept = true

  tags = {
    Name = "VPC-Peering-Connection"
  }
}