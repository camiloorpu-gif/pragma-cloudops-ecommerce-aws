# 🛒 Arquitectura Cloud E-commerce JFC (Serverless & Microservicios)

## 📌 Contexto del Proyecto
Este repositorio contiene el diseño y la Infraestructura como Código (IaC) para la nueva aplicación de e-commerce de la empresa JFC. El objetivo principal es garantizar alta disponibilidad, rendimiento óptimo y escalabilidad automática ante tráfico variable (desde cientos hasta miles de usuarios), manteniendo los costos optimizados mediante un enfoque moderno y Serverless.

## 🏗️ Diagrama de Arquitectura
*(Pendiente por adjuntar)*

## ⚙️ Componentes de la Solución (AWS)
La infraestructura está dividida en 3 capas principales, operando bajo un modelo de alta disponibilidad (Multi-AZ):

### 1. Capa de Red y Seguridad Base (Networking)
* **Amazon VPC:** Red aislada con despliegue en 2 Zonas de Disponibilidad (Multi-AZ).
* **Subredes Públicas y Privadas:** Aislamiento estricto con NAT Gateways.

### 2. Capa de Frontend y Borde
* **Amazon S3 & CloudFront (CDN):** Alojamiento estático y cacheo global.
* **AWS WAF:** Firewall web acoplado a CloudFront.

### 3. Capa de Backend y Cómputo (Serverless)
* **Application Load Balancer (ALB):** Enruta el tráfico dinámico.
* **Amazon ECS con AWS Fargate & Auto Scaling:** Orquestación de contenedores sin administración de servidores.

### 4. Capa de Desacoplamiento
* **Amazon SQS & Cognito:** Colas asíncronas y seguridad de identidades.

### 5. Capa de Datos
* **Amazon Aurora Serverless v2 (PostgreSQL) & ElastiCache:** Persistencia escalable y caché en memoria.