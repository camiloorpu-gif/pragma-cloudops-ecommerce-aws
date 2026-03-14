# ============================================================
# monitoring.tf - Observabilidad para E-commerce JFC
# ============================================================

# 1. SNS - Notificaciones de alarmas
resource "aws_sns_topic" "alerts" {
  name = "ecommerce-alerts"
  tags = { Name = "ecommerce-alerts" }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "devops@ecommerce-jfc.com"
}

# 2. Alarma: CPU alta en Fargate
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "ecommerce-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU de Fargate supera el 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.ecommerce_cluster.name
    ServiceName = aws_ecs_service.ecommerce_service.name
  }
}

# 3. Alarma: Errores 5xx en el ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "ecommerce-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Mas de 10 errores 5xx en el ultimo minuto"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.ecommerce_alb.arn_suffix
  }
}

# 4. Alarma: CPU alta en Aurora
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "ecommerce-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU de Aurora supera el 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster.cluster_identifier
  }
}

# 5. Alarma: CPU alta en Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "ecommerce-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "CPU de Redis supera el 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }
}

# 6. Dashboard unificado
resource "aws_cloudwatch_dashboard" "ecommerce_dashboard" {
  dashboard_name = "ecommerce-jfc-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "CPU Fargate"
          period = 60
          metrics = [["AWS/ECS", "CPUUtilization",
            "ClusterName", aws_ecs_cluster.ecommerce_cluster.name,
            "ServiceName", aws_ecs_service.ecommerce_service.name
          ]]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Errores 5xx ALB"
          period = 60
          metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
            "LoadBalancer", aws_lb.ecommerce_alb.arn_suffix
          ]]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "CPU Aurora"
          period = 60
          metrics = [["AWS/RDS", "CPUUtilization",
            "DBClusterIdentifier", aws_rds_cluster.aurora_cluster.cluster_identifier
          ]]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "CPU Redis"
          period = 60
          metrics = [["AWS/ElastiCache", "CPUUtilization",
            "CacheClusterId", aws_elasticache_cluster.redis.cluster_id
          ]]
        }
      }
    ]
  })
}