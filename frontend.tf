# ============================================================
# frontend.tf - S3, CloudFront y WAF para E-commerce JFC
# ============================================================

# 1. S3 Bucket para alojar el Frontend Estático
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "ecommerce-jfc-frontend-${random_string.suffix.result}"
  force_destroy = true
  tags = { Name = "ecommerce-frontend-bucket" }
}

# Generar un sufijo aleatorio para que el nombre del bucket sea único
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Origin Access Control (OAC) - Seguridad: Solo CloudFront puede leer el S3
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "ecommerce-frontend-oac"
  description                       = "OAC para el bucket de frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Política del Bucket S3 para permitir acceso a CloudFront
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.frontend_distribution.arn
        }
      }
    }]
  })
}

# 3. AWS WAF - Protección contra inyecciones SQL y ataques comunes
# Importante: el WAF para CloudFront debe estar en us-east-1 obligatoriamente
resource "aws_wafv2_web_acl" "frontend_waf" {
  name        = "ecommerce-frontend-waf"
  description = "WAF para proteger CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "frontendWafMetrics"
    sampled_requests_enabled   = true
  }
}

# 4. CloudFront Distribution - Sistema de Cacheo
resource "aws_cloudfront_distribution" "frontend_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.frontend_waf.arn

  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-FrontendOrigin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-FrontendOrigin"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "ecommerce-cloudfront-distribution" }
}