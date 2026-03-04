provider "aws" {
    region = "ap-south-1"
  
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "192.78.0.0/16"
}

resource "aws_subnet" "mysubnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.78.0.0/20"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-sunbet"
  }
}