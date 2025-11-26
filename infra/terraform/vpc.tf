##############################################
# VPC
##############################################

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

##############################################
# INTERNET GATEWAY
##############################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

##############################################
# PUBLIC SUBNET (EXISTS IN AWS)
# ID: subnet-0a338e6c09546b3a2
##############################################

resource "aws_subnet" "public" {
  count                   = 1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.16.0/20"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
  }
}

##############################################
# PRIVATE SUBNET (EXISTS IN AWS)
# ID: subnet-0ed100a990ce18cf8
##############################################

resource "aws_subnet" "private" {
  count             = 1
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "${var.project_name}-private-a"
  }
}

##############################################
# NAT GATEWAY + EIP
# (Optional but included for ECS outbound internet)
##############################################

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }
}

##############################################
# PUBLIC ROUTE TABLE
##############################################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public_rt.id
}

##############################################
# PRIVATE ROUTE TABLE
##############################################

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private_rt.id
}

