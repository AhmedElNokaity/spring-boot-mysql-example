provider "aws" {
    region = "eu-west-3"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable az {}
variable env_prefix {}
variable "my_ip" {}
variable "instance_type" {}
variable "server-root-volume-size" {}
variable "server-data-volume-size" {}
variable "server-root-volume-type" {}



resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id  
  cidr_block = var.subnet_cidr_block
  availability_zone = var.az
  tags = {
    "Name" = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id   
    tags = {
    "Name" = "${var.env_prefix}-igw"
  }
}
resource "aws_route_table" "myapp-route-table" {
  vpc_id= aws_vpc.myapp-vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    "Name" = "${var.env_prefix}-rtb"
  }
}
resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
  
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
}
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

      tags = {
    "Name" = "${var.env_prefix}-default-sg"
  }
  
}
resource "aws_ebs_volume" "data-volume" {
  availability_zone = var.az
  size              = var.server-data-volume-size 
}
resource "aws_instance" "server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  root_block_device {
    volume_size           = var.server-root-volume-size
    volume_type           = var.server-root-volume-type
  }
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.az
  associate_public_ip_address = true
  key_name = "server-key-pair"
  tags = {
    "Name" = "${var.env_prefix}-server"
}
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.data-volume.id
  instance_id = aws_instance.server.id
}