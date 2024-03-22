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
  region = "eu-west-3"
}

# Create a VPC
resource "aws_vpc" "dockerapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

#Create subnets (route table is automatically created)
resource "aws_subnet" "dockerapp-subnet-1" {
  vpc_id            = aws_vpc.dockerapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

#Create Internet Gateway for VPC
resource "aws_internet_gateway" "dockerapp-igw" {
  vpc_id = aws_vpc.dockerapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

#Create route table for new VPC (creates route table with routes that are associated to vpc_id=aws_vpc.dockerapp-vpc.id and also adds route 0.0.0.0/0 )
# resource "aws_route_table" "dockerapp-route-table-1" {
#   vpc_id = aws_vpc.dockerapp-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0" # ruta prema subnetu koji je u var.subnet_cidr_block je automatski kreirana kad se kreirao subnet pa nju ne treba
#     gateway_id = aws_internet_gateway.dockerapp-igw.id
#   }
#   tags = {
#     Name = "${var.env_prefix}-rtb"
#   }
# }

# Associate created subnet with created route table (by default created subnet is associated to route table that is created with it by default. Since we created new route table that also contains 0.0.0.0/0 route we need to associate subnet with that route table)
# Associate created subnet with route table that also has 0.0.0.0/0 route together with 10.0.0.0/16	route
# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id      = aws_subnet.dockerapp-subnet-1.id
#   route_table_id = aws_route_table.dockerapp-route-table-1.id
# }

#Edit default routing table of newly created VPC (instead of adding additional routing table with 0.0.0.0 and associating created subnet with new routing table )
resource "aws_default_route_table" "dockerapp-default-rtb" {
  default_route_table_id = aws_vpc.dockerapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dockerapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-default-rtb"
  }
}

#Edit default security group created for new VPC
resource "aws_default_security_group" "dockerapp-default-sg" {
  vpc_id = aws_vpc.dockerapp-vpc.id

  #Allow ssh from my personal PC
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.my_ip]
  }

  #Allow access for docker container on port 8080 to all IP addresses
  ingress {
    protocol    = "tcp"
    from_port   = var.docker_container_port
    to_port     = var.docker_container_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outgoing traffic
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name : "${var.env_prefix}-default-sg"
  }
}

# # Create security group
# resource "aws_security_group" "allow_ssh" {
#   name        = "allow_ssh"
#   description = "Allow ssh inbound traffic and all outbound traffic"
#   vpc_id      = aws_vpc.dockerapp-vpc.id
#   # ingress {
#   #   from_port = 22
#   # }
#   tags = {
#     Name = "allow_ssh"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
#   security_group_id = aws_security_group.allow_ssh.id
#   cidr_ipv4         = aws_vpc.dockerapp-subnet-1.cidr_block
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.allow_ssh.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

##Create network interface for EC2 instance and assign subnet to it
# resource "aws_network_interface" "dockerapp-server-network-interface" {
#   subnet_id   = aws_subnet.dockerapp-subnet-1.id
#   private_ips = ["172.16.10.100"]

#   tags = {
#     Name = "primary_network_interface for dockerapp server"
#   }
# }

#Fetch latest ami for amazon linux software image that will be used later to pass that ami in ec2 aws_instance
data "aws_ami" "amazon-linux-image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["137112412989"] # AWS
}

#Create public and private key pair to use for ssh connection
#You must run terraform destroy before because for some reason it is not recognized that ec2 instance is using key and must also be updatedid
resource "aws_key_pair" "ssh-key" {
  key_name   = "aws-terraform"
  public_key = file(var.public_key_location)
}

#Create ec2 instance
resource "aws_instance" "dockerapp-server" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = var.instance_type
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  #Assign Subnet
  subnet_id = aws_subnet.dockerapp-subnet-1.id
  #Assign Security group
  vpc_security_group_ids = [aws_default_security_group.dockerapp-default-sg.id]
  #SSH key used for connecting to EC2 instance
  key_name = aws_key_pair.ssh-key.key_name

  tags = {
    Name = "${var.env_prefix}-server"
  }
  #Install and start docker engine on EC2 instance and run simple container to test connection
  user_data = file("C:\\Users\\pgelo\\ASEE_projekti\\DevOps\\aws-terraform\\install-docker-script.sh")
}
