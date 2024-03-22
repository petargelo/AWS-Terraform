#Create subnets (route table is automatically created)
resource "aws_subnet" "dockerapp-subnet-1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

#Create Internet Gateway for VPC
resource "aws_internet_gateway" "dockerapp-igw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

#Edit default routing table of newly created VPC (instead of adding additional routing table with 0.0.0.0 and associating created subnet with new routing table )
resource "aws_default_route_table" "dockerapp-default-rtb" {
  default_route_table_id = var.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dockerapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-default-rtb"
  }
}