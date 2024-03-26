#Fetch latest ami for amazon linux software image that will be used later to pass that ami in ec2 aws_instance
data "aws_ami" "amazon-linux-image" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.image_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["137112412989"] # AWS
}

#Edit default security group created for new VPC
resource "aws_default_security_group" "dockerapp-default-sg" {
  vpc_id = var.dockerapp_vpc

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
  subnet_id = var.subnet_id
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