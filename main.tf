terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone ="ap-south-1a"

  tags = {
    Name = "pubsub"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone ="ap-south-1b"

  tags = {
    Name = "prisub"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_route_table" "nrt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

 
  tags = {
    Name = "myrout"
  }
}

resource "aws_route_table_association" "routeassco" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.nrt.id
}
resource "aws_eip" "lb" {
  
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "nat"
  }


}
resource "aws_route_table" "nrt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

 
  tags = {
    Name = "myrout_pri"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.nrt.id
}

resource "aws_vpc" "ci" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.20.0.0/16"
}

resource "aws_security_group" "all" {
  name        = "all"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "all"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allipv4" {
  security_group_id = aws_security_group.all.id
  cidr_ipv4         = aws_vpc.my_vpc.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allipv4" {
  security_group_id = aws_security_group.all.id
  cidr_ipv4         = aws_vpc.my_vpc.cidr_block
  from_port         = 80
  ip_protocol       = "http"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "newins" {
  ami                     = "ami-0e670eb768a5fc3d4 "
  instance_type           = "t2.micro"
  key_name                =  "new"
  subnet_id               = "aws_subnet.pubsub"
  vpc_security_group_ids  =["aws_security_group.all"]
  key_name                ="new"
  associate_public_ip_address="true"
 
}

resource "aws_instance" "newinss" {
  ami                     = "ami-0e670eb768a5fc3d4 "
  instance_type           = "t2.micro"
  key_name                =  "new"
  subnet_id               = "aws_subnet.prisub"
  vpc_security_group_ids  =["aws_security_group.all"]
  key_name                ="new"
  associate_public_ip_address="true"
}
  