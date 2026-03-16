provider "aws" {
    region = var.region
  
}

resource "aws_vpc" "my-vpc" {
  cidr_block = var.mumbai_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name= var.vpc_name
  }
}

resource "aws_subnet" "mysubnet-1" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = var.public_cidr_block
  map_public_ip_on_launch = true
  availability_zone = var.public_available_zone
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "mysubnet-2" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = var.private_cidr_block
  availability_zone = var.private_available_zone
  map_public_ip_on_launch = false
  tags = {
    Name = var.private_subnet_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = var.igw_name
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
    Name = var.nat_name
  }
}

resource "aws_route_table" "NAT-tb" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my-ngw.id
  }

  tags = {
    Name = var.nat_route_table_name
  }
}

resource "aws_route_table_association" "private-assoc" {
  subnet_id = aws_subnet.mysubnet-2.id
  route_table_id = aws_route_table.NAT-tb.id
  
}

resource "aws_security_group" "my-sg-1" {
  name        = var.security_group_name_1
  description = var.description_sg_1
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my-sg-2" {
  name        = var.security_group_name
  description = var.description_sg
  vpc_id      = aws_vpc.my-vpc.id


  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.my-sg-1.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "my_db_subnet" {
  name = "my-db-subnet-group"

  subnet_ids = [
    aws_subnet.mysubnet-1.id,
    aws_subnet.mysubnet-2.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "my_db" {

  identifier = "mariadb-instance"
  allocated_storage = 10
  storage_type      = "gp2"
  engine         = "mariadb"
  engine_version = "10.6"
  instance_class = "db.t4g.micro"
  db_name  = "studentapp"
  username = "arya"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet.name
  vpc_security_group_ids = [aws_security_group.my-sg-2.id]

  publicly_accessible = false
  skip_final_snapshot = true

}

resource "aws_instance" "Ec2Instance" {
    ami           = var.image_instance
    instance_type = var.instance_type
    key_name = var.instance_key
    vpc_security_group_ids = [aws_security_group.my-sg-1.id]
    subnet_id = aws_subnet.mysubnet-1.id
    user_data = base64encode(file("userdata.sh"))
    tags = {
      Name = var.public_instance_name
    }
}

resource "aws_instance" "db-instance" {
    ami           = var.image_instance
    instance_type = var.instance_type
    key_name = var.instance_key
    vpc_security_group_ids = [aws_security_group.my-sg-1.id]
    subnet_id = aws_subnet.mysubnet-2.id
    user_data = base64encode(file("userdata_2.sh"))
    tags = {
      Name = var.private_instance_name
    }
}



