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

#Call module from modules/subnet directory so it can be used here
module "dockerapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block #Assign value from parent values file - terraform-dockerapp-dev.tfvars to variable subnet_cidr_block defined in parent variables.tf and pass it to child variables file in modules/subnet/variables.tf
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.dockerapp-vpc.id # Reference value from resource object to child module variable (in this case value from vpc) 
  default_route_table_id = aws_vpc.dockerapp-vpc.default_route_table_id
}

module dockerapp-server {
  source = "./modules/webserver"
  dockerapp_vpc = aws_vpc.dockerapp-vpc.id
  my_ip = var.my_ip
  docker_container_port = var.docker_container_port
  image_name = var.image_name
  public_key_location = var.public_key_location
  instance_type = var.instance_type
  subnet_id = module.dockerapp-subnet.subnet.id #Reference value from child module subnet outputs.tf entry and call attribute id of the object defined in "subnet" output
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
}