# 1. Crear el Clúster de ECS (Orquestador de Contenedores)
resource "aws_ecs_cluster" "ecommerce_cluster" {
  name = "ecommerce-fargate-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # Habilita métricas detalladas para monitoreo
  }

  tags = {
    Name = "ecommerce-ecs-cluster"
  }
}

# 2. Crear un Security Group para el Balanceador de Carga (Permitir tráfico web)
resource "aws_security_group" "alb_sg" {
  name        = "ecommerce-alb-sg"
  description = "Permitir trafico HTTP entrante desde internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Abierto a todo internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-alb-sg"
  }
}

# 3. Crear el Application Load Balancer (ALB)
resource "aws_lb" "ecommerce_alb" {
  name               = "ecommerce-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # Se coloca en las subredes publicas creadas en network.tf
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] 

  tags = {
    Name = "ecommerce-alb"
  }
}