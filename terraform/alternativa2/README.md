# Alternativa 2: ECS Fargate

Esta carpeta contiene el código de Terraform para desplegar la solución usando Amazon ECS Fargate.

## Componentes

- **Amazon ECS Fargate**: Ejecuta contenedores que procesan transacciones.
- **Amazon SQS**: Almacena las transacciones pendientes.
- **Application Load Balancer (ALB)**: Distribuye la carga entre los contenedores.
- **VPC, Subnets, y Security Groups**: Configuración de red para aislar y proteger los recursos.

## Requisitos

- Terraform >= 1.0
- AWS CLI configurado con credenciales válidas.

## Despliegue

1. Inicializa Terraform:
   ```bash
   terraform init
   terraform apply
   terraform destroy
    ```