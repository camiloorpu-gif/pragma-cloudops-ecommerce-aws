# 1. Crear un grupo de subredes para la Base de Datos (usando las subredes privadas)
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "ecommerce-aurora-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "ecommerce-aurora-subnet-group"
  }
}

# 2. Crear el Clúster de Aurora Serverless (PostgreSQL)
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "ecommerce-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned" # Serverless v2 requiere este modo
  engine_version     = "15.3"
  database_name      = "ecommerce_db"
  master_username    = "dbadmin"
  master_password    = "Pragma2026SecurePass!" # En produccion esto debe ir oculto (Secrets Manager)
  
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  skip_final_snapshot    = true # Para que podamos borrarla facilmente en pruebas

  # Configuración del motor Serverless v2 (escalado automático)
  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }

  tags = {
    Name = "ecommerce-aurora-cluster"
  }
}

# 3. Crear una instancia Serverless para el Clúster
resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}

# 4. Crear una Cola SQS para pedidos asíncronos (Desacoplamiento)
resource "aws_sqs_queue" "ecommerce_orders_queue" {
  name                      = "ecommerce-orders-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600 # 4 días
  receive_wait_time_seconds = 0

  tags = {
    Name = "ecommerce-orders-queue"
  }
}