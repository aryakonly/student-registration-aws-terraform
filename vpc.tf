provider "aws" {
    region = "ap-south-1"
  
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "192.78.0.0/16"
}

resource "aws_subnet" "mysubnet-1" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "192.78.0.0/20"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-sunbet"
  }
}

resource "aws_subnet" "mysubnet-2" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "192.78.16.0/20"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-sunbet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_default_route_table" "default-tb" {
  default_route_table_id = aws_vpc.my-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public-assoc" {
  subnet_id = aws_subnet.mysubnet-1.id
  route_table_id = aws_default_route_table.default-tb.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my-ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.mysubnet-1.id

  tags = {
    Name = "my-ngw"
  }
}

resource "aws_route_table" "NAT-tb" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my-ngw.id
  }

  tags = {
    Name = "NAT-tb"
  }
}

resource "aws_route_table_association" "private-assoc" {
  subnet_id = aws_subnet.mysubnet-2.id
  route_table_id = aws_route_table.NAT-tb.id
  
}

resource "aws_instance" "Ec2Instance" {
    ami           = "ami-051a31ab2f4d498f5"
    instance_type = "t3.micro"
    key_name = "mumbai-key"
    vpc_security_group_ids = ["sg-0098f50bfc62f633d"]
    subnet_id = aws_subnet.mysubnet-1.id
    tags = {
      Name = "Ec2Instance"
    }
}