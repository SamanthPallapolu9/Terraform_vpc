#AWS VPC
#========

#providers.tf

provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

#vpc.tf

resource "aws_vpc" "DevOpsScenerio" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "DevOpsScenerio"
  }
}

#Create Subnets in DevOpsScenerio

resource "aws_subnet" "DevOpsScenerio-public" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "DevOpsScenerio-public"
  }
}


resource "aws_subnet" "DevOpsScenerio-private_DEV" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "DevOpsScenerio-private_DEV"
  }
}


resource "aws_subnet" "DevOpsScenerio-private_STAGE" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "DevOpsScenerio-private_STAGE"
  }
}

#Define the IGW

resource "aws_internet_gateway" "DevOpsScenerio-gw" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  
  tags = {
    Name = "DevOpsScenerio-ig"
  }
}

#Elastic ips

resource "aws_eip" "ip" {
  vpc      = true
}  


#NAT gateway

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.DevOpsScenerio-public.id     

  tags = {
    Name = "NGW"
  }
}

#Define the RT for DevOpsScenerio

resource "aws_route_table" "DevOpsScenerio-rt1" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  
  route {
    cidr_block = "0.0.0.0/0"    #all ips
	gateway_id = aws_internet_gateway.DevOpsScenerio-gw.id
  }
  
  tags = {
    Name = "DevOpsScenerio_routetable"
  }
}

resource "aws_route_table" "DevOpsScenerio-rt2" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  
  route {
  cidr_block = "0.0.0.0/0"    #all ips
	gateway_id = aws_nat_gateway.ngw.id
  }
  
  tags = {
    Name = "main_DevOpsScenerio_routetable"
  }
}

resource "aws_route_table" "DevOpsScenerio-rt3" {
  vpc_id = aws_vpc.DevOpsScenerio.id
  
  route {
  cidr_block = "0.0.0.0/0"    #all ips
	gateway_id = aws_nat_gateway.ngw.id
  }
  
  tags = {
    Name = "standby_DevOpsScenerio_routetable"
  }
}


#Define the routing association with a route table
# and a subnet or a route table and an internet gateway or a virtual private gateway

resource "aws_route_table_association" "as_1" {
  subnet_id = aws_subnet.DevOpsScenerio-public.id
  route_table_id = aws_route_table.DevOpsScenerio-rt1.id
}

resource "aws_route_table_association" "as_2" {
  subnet_id = aws_subnet.DevOpsScenerio-private_DEV.id
  route_table_id = aws_route_table.DevOpsScenerio-rt2.id
}

resource "aws_route_table_association" "as_3" {
  subnet_id = aws_subnet.DevOpsScenerio-private_STAGE  .id
  route_table_id = aws_route_table.DevOpsScenerio-rt3.id
}


#Security Groups

resource "aws_security_group" "sg" {
  name        = "First-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.DevOpsScenerio.id

  ingress = [
    {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.DevOpsScenerio.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self = false
    }
  ]

  egress = [
    {
      description      = "allow all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self = false
    }
  ]

  tags = {
    Name = "First-SG"
  }
}

