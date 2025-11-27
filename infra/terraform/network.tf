###############################################
# NETWORKING FOR kafka-enterprise-orders
# - Uses existing VPC (var.existing_vpc_id)
# - Creates 2 public + 2 private subnets in 2 AZs
# - Creates 2 NAT gateways + route tables
###############################################

###############################################
# INTERNET GATEWAY
###############################################
resource "aws_internet_gateway" "this" {
  vpc_id = var.existing_vpc_id

  tags = {
    Name = "kafka-enterprise-orders-igw"
  }
}

###############################################
# PUBLIC SUBNETS (for ALB)
###############################################
resource "aws_subnet" "public_a" {
  vpc_id                  = var.existing_vpc_id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "kafka-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = var.existing_vpc_id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "kafka-public-b"
  }
}

###############################################
# PRIVATE SUBNETS (for ECS Fargate)
###############################################
resource "aws_subnet" "private_a" {
  vpc_id            = var.existing_vpc_id
  cidr_block        = "10.10.4.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "kafka-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = var.existing_vpc_id
  cidr_block        = "10.10.5.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "kafka-private-b"
  }
}

###############################################
# ELASTIC IPs FOR NAT GATEWAYS
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

###############################################
# NAT GATEWAYS (one per AZ)
###############################################
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "kafka-nat-a"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "kafka-nat-b"
  }

  depends_on = [aws_internet_gateway.this]
}

###############################################
# ROUTE TABLES
###############################################

# Public route table (for ALB subnets)
resource "aws_route_table" "public" {
  vpc_id = var.existing_vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "kafka-public-rt"
  }
}

# Private RT for AZ a
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

# Private RT for AZ b
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

# Public
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}
