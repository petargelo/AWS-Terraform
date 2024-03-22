#Used to validate aws_ami.amazon-linux-image details with terraform plan
#Remove .id suffix to get all data 
output "aws_ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}

#Used to get EC2 server public IP after it is created
output "ec2_public_ip" {
  value = aws_instance.dockerapp-server.public_ip
}