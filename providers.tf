terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Versionn terraform 
  required_version = ">= 1.2.0"
}

# Configuración del proveedor de AWS
provider "aws" {
  region = "us-east-1"
  
  # Estas etiquetas se aplicarán automáticamente a todo lo que creemos
  default_tags {
    tags = {
      Project     = "Pragma-Ecommerce-JFC"
      Environment = "Dev"
      ManagedBy   = "Terraform"
      Owner       = "Camilo Ortiz"
    }
  }
}