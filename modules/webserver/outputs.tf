output "ami" {
    value = data.aws_ami.amazon-linux-image
}

output "aws_instance" {
    value = aws_instance.dockerapp-server
}