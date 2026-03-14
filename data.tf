# ============================================================
# data.tf - Base de datos y caché para E-commerce JFC
# ============================================================

# 1. Contraseña segura generada por Terraform
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]"
}

# 2. Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "ecommerce/db_password"
  description = "Contraseña maestra de Aurora"
}

resource "aws_secretsmanager_secret_version" "password_val" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# 3. Subnet Group para Aurora
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name = "ecommerce-aurora-subnet-group"
  subnet_ids = [
    aws_subnet.private_data_1.id,
    aws_subnet.private_data_2.id
  ]
  tags = { Name = "ecommerce-aurora-subnet-group" }
}

# 4. Cluster Aurora Serverless v2
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier     = "ecommerce-aurora-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "15.3"
  database_name          = "ecommerce_db"
  master_username        = "dbadmin"
  master_password        = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  skip_final_snapshot    = true

  serverlessv2_scaling_configuration {
    max_capacity = 4.0
    min_capacity = 0.5
  }

  tags = { Name = "ecommerce-aurora-cluster" }
}

# 5. Instancia Aurora Serverless v2
resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
  tags               = { Name = "ecommerce-aurora-instance" }
}

# 6. Subnet Group para ElastiCache
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name = "ecommerce-redis-subnet-group"
  subnet_ids = [
    aws_subnet.private_data_1.id,
    aws_subnet.private_data_2.id
  ]
}

# 7. ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "ecommerce-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.elasticache_sg.id]

  tags = { Name = "ecommerce-redis" }
}