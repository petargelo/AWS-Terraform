Provision AWS infrastructure using custom made subnet and webserver (EC2) modules.

0) Create AWS Policy that will enable user that applies terraform configuration (admin user) to create VPC
1) Create custom VPC 
2) Create custom subnet 
 - in one availability zone of the region
3) Create route table & Internet gateway
4) Provision EC2 Instance - virtual server that will host Docker container
5) Deploy nginx Docker container
6) Create Security Group (firewall) - enable access from the browser to docker container and enable ssh to the EC2 instance

##################
141.
VPC with subnet inside.
Connect to internet using aws internet gateway and configured it in the route table.
Created security group that allows 22 and 8080 ports. This security group will later be used by ec2 instance
##################