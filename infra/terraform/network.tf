###############################################
# NETWORKING — USE EXISTING SUBNETS + IGW
# AND CREATE ONLY NAT + ROUTE TABLES
###############################################

# Existing Internet Gateway attached to this VPC
data "aws_internet_gateway" "this" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.existing_vpc_id]
  }
}

###############################################
# EXISTING SUBNETS (already created before)
# We identify them by VPC + CIDR
###############################################

# Public subnet in us-east-2a, CIDR 10.10.1.0/24
data "aws_subnet" "public_a" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = ["10.10.1.0/24"]
  }
}

# Public subnet in us-east-2b, CIDR 10.10.2.0/24
data "aws_subnet" "public_b" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = ["10.10.2.0/24"]
  }
}

# Private subnet in us-east-2a, CIDR 10.10.4.0/24
data "aws_subnet" "private_a" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = ["10.10.4.0/24"]
  }
}

# Private subnet in us-east-2b, CIDR 10.10.5.0/24
data "aws_subnet" "private_b" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = ["10.10.5.0/24"]
  }
}

###############################################
# NAT GATEWAYS (new, Terraform-managed)
###############################################

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "kafka-nat-a-eip"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name = "kafka-nat-b-eip"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = data.aws_subnet.public_a.id

  tags = {
    Name = "kafka-nat-a"
  }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = data.aws_subnet.public_b.id

  tags = {
    Name = "kafka-nat-b"
  }
}

###############################################
# ROUTE TABLES
###############################################

# Public route table for ALB subnets
resource "aws_route_table" "public" {
  vpc_id = var.existing_vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.this.id
  }

  tags = {
    Name = "kafka-public-rt"
  }
}

# Private route table for us-east-2a
resource "aws_route_table" "private_a" {
  vpc_id = var.existing_vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "kafka-private-a-rt"
  }
}

# Private route table for us-east-2b
resource "aws_route_table" "private_b" {
  vpc_id = var.existing_vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "kafka-private-b-rt"
  }
}

###############################################
# ROUTE TABLE ASSOCIATIONS
###############################################

resource "aws_route_table_association" "public_a" {
  subnet_id      = data.aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = data.aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = data.aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = data.aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}
