resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}
resource "aws_subnet" "my-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true


  tags = {
    Name = "my-subnet"
    "kubernetes.io/cluster/sai-eks-cluster"  = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }
}
resource "aws_subnet" "my-subnet-02" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true


  tags = {
    Name = "my-subnet-02"
    "kubernetes.io/cluster/sai-eks-cluster"  = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }
}
resource "aws_internet_gateway" "my-gateway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-gateway"
  }
}
resource "aws_route_table" "my-route-01" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-route-01"
  }
}
resource "aws_route_table_association" "my_route_association" {
  subnet_id      = aws_subnet.my-subnet.id
  route_table_id = aws_route_table.my-route-01.id
}
resource "aws_route_table_association" "my_route_association_02" {
  subnet_id      = aws_subnet.my-subnet-02.id
  route_table_id = aws_route_table.my-route-01.id
}
resource "aws_security_group" "jenkins-c-sg" {
  name        = "jenkins-c-sg"
  description = "Jenkins controller access"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.43.225.176/32"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["49.43.225.176/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "jenkins-a-sg" {
  name        = "jenkins-a-sg"
  description = "Jenkins build agents"
  vpc_id      = aws_vpc.my-vpc.id

  # SSH from Controller SG
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins-c-sg.id]
  }

  # Custom app port for testing
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["49.43.225.176/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "jenkins-c" {
  ami                         = "ami-0317b0f0a0144b137"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.my-subnet.id
  key_name                    = "vasudev"
  associate_public_ip_address = true


  vpc_security_group_ids = [
    aws_security_group.jenkins-c-sg.id
  ]
  credit_specification {
    cpu_credits = "standard"
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
  }

  tags = {
    Name = "jenkins-c"
  }
}
resource "aws_instance" "jenkins-agent" {
  ami                         = "ami-0317b0f0a0144b137"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.my-subnet-02.id
  key_name                    = "vasudev"
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.jenkins-a-sg.id
  ]
  credit_specification {
    cpu_credits = "standard"
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
  }

  tags = {
    Name = "jenkins-agent"
  }
}
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-2"
  }
}
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.my-subnet.id  # your public subnet

  tags = {
    Name = "nat-gateway"
  }
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}



