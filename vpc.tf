# Create a VPC for our environment
resource "aws_vpc" "vpc_web" {
  cidr_block = "192.168.0.0/16"
}

# Create an internet gateway to give our VPC access to internet
resource "aws_internet_gateway" "inet_gate" {
  vpc_id = aws_vpc.vpc_web.id
  tags = {
    Name = "internet_gateway_nginx"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc_web.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gate.id
}

# Create a public subnet for NATgateway
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_web.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_nginx"
  }
}

# Create a private subnet for our instance
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_web.id
  cidr_block        = "192.168.100.0/24"
  #availability_zone = "us-west-2a"
  tags = {
    Name = "private_subnet"
  }
}
resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.public_subnet.id
  connectivity_type  = "private"
  # To ensure proper ordering, add Internet Gateway as dependency
  depends_on = [aws_internet_gateway.inet_gate]
  tags = {
    Name = "NATgateway"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_web.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_web.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inet_gate.id
  }
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table_association" "rta_private_subnet" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "rta_public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
