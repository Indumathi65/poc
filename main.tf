terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get AZs (we'll use first two if available)
data "aws_availability_zones" "available" {
  state = "available"
}

# --------------------------
# VPC
# --------------------------
resource "aws_vpc" "dms" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dms"
  }
}

# --------------------------
# PUBLIC SUBNET
# --------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.dms.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = lookup(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "dms-public-subnet"
  }
}

# --------------------------
# PRIVATE SUBNET
# --------------------------
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.dms.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = lookup(data.aws_availability_zones.available.names, 1)

  tags = {
    Name = "dms-private-subnet"
  }
}

# --------------------------
# INTERNET GATEWAY
# --------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dms.id

  tags = {
    Name = "dms-igw"
  }
}

# --------------------------
# PUBLIC ROUTE TABLE -> IGW
# --------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.dms.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "dms-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------------
# EIP for NAT
# --------------------------
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "dms-nat-eip"
  }
}

# --------------------------
# NAT GATEWAY in Public Subnet
# --------------------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "dms-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# --------------------------
# PRIVATE ROUTE TABLE -> NAT
# --------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.dms.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "dms-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

# --------------------------
# SECURITY GROUP (Allow all in/out)
# --------------------------
resource "aws_security_group" "allow_all" {
  name        = "dms-allow-all"
  description = "Allow all inbound and outbound"
  vpc_id      = aws_vpc.dms.id

  # Ingress - allow all
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dms-allow-all"
  }
}