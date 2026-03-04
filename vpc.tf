provider "aws" {
    region = "ap-south-1"
  
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "192.78.0.0/16"
}

resource "aws_subnet" "mysubnet-1" {
  vpc_id = "vpc-0bba4a05381dfa9f9"
  cidr_block = "192.78.0.0/20"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-sunbet"
  }
}

resource "aws_subnet" "mysubnet-2" {
  vpc_id = "vpc-0bba4a05381dfa9f9"
  cidr_block = "192.78.16.0/20"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-sunbet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "vpc-0bba4a05381dfa9f9"

  tags = {
    Name = "my-igw"
  }
}

resource "aws_default_route_table" "example" {
  default_route_table_id = "rtb-010c1c7fac94d3095"

  route {
    cidr_block = "192.78.0.0/24"
    gateway_id = aws_internet_gateway.example.id
  }
}