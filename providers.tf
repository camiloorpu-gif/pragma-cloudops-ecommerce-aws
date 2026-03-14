terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"

  # NOTA 
  # Desactivé el remote state temporalmente para que puedan probar el código 
  # sin que les lance un "Access Denied" por los permisos del bucket. 
  # Para prod sí o sí va con S3.
   /*
  backend "s3" {
    bucket         = "ecommerce-jfc-terraform-state" 
    key            = "ecommerce/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
  */
}

# Provider principal
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "Pragma-Ecommerce-JFC"
      Environment = "Dev"
      ManagedBy   = "Terraform"
      Owner       = "Camilo Ortiz"
    }
  }
}