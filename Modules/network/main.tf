terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
  }
  required_version = ">=0.14"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  
  tags = {
    Name = "MainVPC-Group8-${var.env}"
    Environment = "${var.env}"
    Project = "MyProject"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index * 4)
  availability_zone = element(var.availability_zones, count.index)
  
   tags = {
    Name = "PublicSubnet-Group8-${count.index}"
    Environment = "${var.env}"
    Project = "MyProject"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)
  availability_zone = element(var.availability_zones, count.index)
  
   tags = {
    Name = "PrivateSubnet-Group8-${count.index}"
    Environment = "${var.env}"
    Project = "MyProject"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_subnet_rts" {
  count  = length(aws_subnet.public_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_rtas" {
  count         = length(aws_subnet.public_subnets)
  subnet_id     = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_subnet_rts[count.index].id
}

resource "aws_route_table" "private_subnet_rts" {
  count  = length(aws_subnet.private_subnets)
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id  = aws_eip.nat_eips[0].id
  subnet_id      = aws_subnet.public_subnets[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_eip" "nat_eips" {
  count = length(aws_subnet.private_subnets)
}

resource "aws_route" "private_subnet_routes" {
  count             = length(aws_subnet.private_subnets)
  route_table_id   = aws_route_table.private_subnet_rts[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id  = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_subnet_rtas" {
  count           = length(aws_subnet.private_subnets)
  subnet_id       = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_subnet_rts[count.index].id
}