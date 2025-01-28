# Alternativa 1: Serverless (Lambda + SQS)

Esta carpeta contiene el código de Terraform para desplegar la solución Serverless usando AWS Lambda y SQS.

## Componentes

- **AWS Lambda**: Procesa las transacciones desde SQS.
- **Amazon SQS**: Almacena las transacciones pendientes.
- **API Gateway**: Expone un endpoint para recibir transacciones.
- **IAM Roles y Políticas**: Permisos para Lambda y API Gateway.

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