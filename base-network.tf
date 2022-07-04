resource "aws_vpc" "core_vpc" {
  cidr_block = "172.24.0.0/24"
}

resource "aws_subnet" "core_subnet_a" {
  vpc_id            = aws_vpc.core_vpc.id
  cidr_block        = "172.24.0.0/28"
  availability_zone = "ap-southeast-2a"
}
resource "aws_subnet" "core_subnet_b" {
  vpc_id            = aws_vpc.core_vpc.id
  cidr_block        = "172.24.0.16/28"
  availability_zone = "ap-southeast-2b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.core_vpc.id
}

resource "aws_route_table" "default_route" {
  vpc_id = aws_vpc.core_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.core_subnet_a.id
  route_table_id = aws_route_table.default_route.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.core_subnet_b.id
  route_table_id = aws_route_table.default_route.id
}