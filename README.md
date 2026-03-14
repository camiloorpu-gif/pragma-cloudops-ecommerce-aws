# Arquitectura Cloud E-commerce JFC
### Solución Serverless y Microservicios en AWS

---

## Contexto

La empresa JFC requiere una plataforma de e-commerce lista para producción, capaz de manejar tráfico variable desde cientos hasta miles de usuarios simultáneos, con alta disponibilidad, costos optimizados y mínima gestión manual de infraestructura.

---

## Diagrama de Arquitectura

*(Adjuntar imagen del diagrama)*

---

## Stack Tecnológico

| Capa | Servicio AWS | Justificación |
|---|---|---|
| Red | VPC Multi-AZ, Subredes, NAT Gateway | Aislamiento y alta disponibilidad |
| Frontend | S3 + CloudFront | Serverless, caché global, costo mínimo |
| Seguridad perimetral | WAF, Route 53 | Protección contra ataques |
| Backend | ECS Fargate + ALB + Auto Scaling | Contenedores serverless, escalabilidad automática |
| Imágenes Docker | Amazon ECR | Repositorio privado con escaneo de vulnerabilidades |
| Base de datos | Aurora Serverless v2 (PostgreSQL) | ACID, escala automática por demanda |
| Cache | ElastiCache Redis | Respuesta en submilisegundos para consultas frecuentes |
| Secretos | AWS Secrets Manager | Cero credenciales en texto plano |
| Observabilidad | CloudWatch Logs, Metrics, Alarms | Visibilidad total del sistema |

---

## Flujo de Trafico

```
Usuario
  └─► Route 53 (DNS)
        └─► CloudFront (CDN + WAF)
              ├─► S3 (contenido estatico: HTML, CSS, JS)
              └─► ALB (peticiones dinamicas)
                    └─► ECS Fargate (microservicios)
                          ├─► Aurora Serverless v2 (escrituras/lecturas)
                          └─► ElastiCache Redis (lecturas en cache)
```

---

## Seguridad

La red esta dividida en tres niveles de subredes: publicas para el ALB y NAT Gateway, privadas de computo para Fargate, y privadas de datos para Aurora y Redis. Nada de la capa de datos es accesible desde internet.

El WAF acoplado a CloudFront bloquea inyecciones SQL, XSS y ataques DDoS antes de que el trafico llegue a la infraestructura interna.

Las credenciales de Aurora son generadas por Terraform con random_password y almacenadas en AWS Secrets Manager. Los contenedores las leen en tiempo de ejecucion. Ninguna contrasena existe en el codigo fuente.

---

## Escalabilidad y Disponibilidad

Toda la infraestructura se despliega en 2 Zonas de Disponibilidad. Si una falla, la otra asume la carga sin intervencion manual.

El Auto Scaling de Fargate esta configurado con Target Tracking al 70% de CPU, escalando entre 2 y 10 tareas. El scale out ocurre en 60 segundos para responder ante picos, y el scale in en 300 segundos para evitar fluctuaciones innecesarias.

Aurora Serverless v2 escala su capacidad de computo entre 0.5 y 4.0 ACUs segun la demanda. En horas de baja demanda la capacidad se reduce al minimo, optimizando costos.

ElastiCache Redis absorbe las lecturas frecuentes como el catalogo de productos, protegiendo a Aurora de sobrecarga en picos de trafico.

---

## Decisiones de Diseno

**Fargate sobre EKS**
EKS cobra aproximadamente 70 USD al mes de base por el Control Plane, independiente del trafico. Fargate no tiene costo base, se paga por vCPU y memoria consumida. Para trafico variable, Fargate es mas eficiente en costo.

**Aurora Serverless sobre RDS estandar**
Las transacciones de un e-commerce requieren garantias ACID. Aurora Serverless v2 las provee con escalado automatico de capacidad, eliminando el sobreaprovisionamiento de una instancia fija.

**Un solo NAT Gateway**
Decision de costo. Un segundo NAT Gateway agregaria resiliencia ante la falla de una AZ pero incrementa el costo en aproximadamente 32 USD al mes. Puede revisarse segun el SLA del negocio.

**Fargate sobre Lambda**
Lambda tiene un limite de 15 minutos por ejecucion. Procesos como sincronizacion de inventario o generacion de reportes pueden superar ese limite. Fargate no tiene esta restriccion.

---

## Estimacion de Costos Mensual

| Servicio | Costo estimado |
|---|---|
| AWS Fargate | $17.77 USD |
| Aurora Serverless v2 | $47.61 USD |
| NAT Gateway | $65.78 USD |
| Application Load Balancer | $22.27 USD |
| ElastiCache Redis | $12.41 USD |
| CloudFront | $0.30 USD |
| WAF | $10.60 USD |
| S3 | $0.03 USD |
| Secrets Manager | $0.41 USD |
| CloudWatch | $6.02 USD |
| Total mensual estimado | $183.20 USD |

Fargate y Aurora escalan segun consumo real. En horas de baja demanda el costo puede reducirse significativamente.

