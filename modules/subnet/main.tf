resource "aws_subnet" "public-subnet-1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = var.avail_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env_prefix}-prviate-subnet-1"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = var.default_route_table_id
  #vpc_id                = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
}


resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
