# ============================================================
# network.tf - Red base para E-commerce JFC
# ============================================================

# 1. VPC Principal
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "ecommerce-vpc" }
}

# 2. Subredes Públicas (ALB y NAT Gateway)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "ecommerce-public-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "ecommerce-public-2" }
}

# 3. Subredes Privadas - Cómputo (Fargate)
resource "aws_subnet" "private_compute_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "ecommerce-private-compute-1" }
}

resource "aws_subnet" "private_compute_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "ecommerce-private-compute-2" }
}

# 4. Subredes Privadas - Datos (Aurora + ElastiCache)
resource "aws_subnet" "private_data_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "ecommerce-private-data-1" }
}

resource "aws_subnet" "private_data_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "ecommerce-private-data-2" }
}

# 5. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "ecommerce-igw" }
}

# 6. NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "ecommerce-nat-eip" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags          = { Name = "ecommerce-nat-gw" }
  depends_on    = [aws_internet_gateway.igw]
}

# 7. Route Table Pública
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "ecommerce-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 8. Route Table Privada
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "ecommerce-private-rt" }
}

resource "aws_route_table_association" "private_compute_1" {
  subnet_id      = aws_subnet.private_compute_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_compute_2" {
  subnet_id      = aws_subnet.private_compute_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 9. Security Group - ALB
resource "aws_security_group" "alb_sg" {
  name        = "ecommerce-alb-sg"
  description = "Trafico HTTP/HTTPS hacia el ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecommerce-alb-sg" }
}

# 10. Security Group - Fargate
resource "aws_security_group" "fargate_sg" {
  name        = "ecommerce-fargate-sg"
  description = "Trafico hacia contenedores solo desde ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecommerce-fargate-sg" }
}

# 11. Security Group - Aurora
resource "aws_security_group" "aurora_sg" {
  name        = "ecommerce-aurora-sg"
  description = "Acceso a Aurora solo desde Fargate"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.fargate_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecommerce-aurora-sg" }
}

# 12. Security Group - ElastiCache
resource "aws_security_group" "elasticache_sg" {
  name        = "ecommerce-elasticache-sg"
  description = "Acceso a Redis solo desde Fargate"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.fargate_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecommerce-elasticache-sg" }
}