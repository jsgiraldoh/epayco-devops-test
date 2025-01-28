# epayco-devops-test

# Explicación General del Código de Terraform

Este repositorio contiene dos alternativas para resolver el problema de procesamiento de transacciones en AWS, utilizando **Infraestructura como Código (IaC)** con Terraform. A continuación, se explica la estructura y componentes clave del código.

---

## Estructura del Directorio `terraform/`

terraform/
├── alternativa1/ # Solución Serverless (Lambda + SQS)
│ ├── main.tf # Configuración de Lambda, SQS, API Gateway y roles IAM
│ ├── variables.tf # Variables como región y entorno
│ └── README.md # Instrucciones específicas para esta alternativa
│
├── alternativa2/ # Solución con Contenedores (ECS Fargate)
│ ├── main.tf # Configuración de ECS, VPC, ALB, SQS y seguridad
│ ├── variables.tf # Variables como región, entorno e imagen de Docker
│ └── README.md # Instrucciones específicas para esta alternativa
│
└── README.md # Este archivo (explicación general)

---

## Componentes Comunes

### 1. **Variables Configurables**
   - **`aws_region`**: Región de AWS donde se despliega la infraestructura (ej: `us-east-1`).
   - **`environment`**: Entorno de despliegue (`dev`, `stg`, `prod`), usado para nombrar recursos.
   - **`ecs_image`** (Alternativa 2): Imagen de Docker para los contenedores ECS.

### 2. **Manejo de Redes**
   - **VPC**: Aislamiento lógico de recursos.
   - **Subnets Públicas/Privadas**: Segmentación de red para seguridad.
   - **Security Groups**: Reglas de firewall para controlar tráfico.
   - **Internet/NAT Gateways**: Conectividad a Internet para recursos en subnets públicas/privadas.

### 3. **IAM Roles y Políticas**
   - **Lambda (Alternativa 1)**: Permisos para acceder a SQS y ejecutarse en una VPC.
   - **ECS Fargate (Alternativa 2)**: Permisos para consumir mensajes de SQS.

---

## Alternativa 1: Serverless (Lambda + SQS)

### Arquitectura
- **API Gateway**: Endpoint público para recibir transacciones.
- **SQS**: Cola de mensajes para almacenar transacciones pendientes.
- **Lambda**: Función serverless que procesa transacciones desde SQS.
- **RDS**: Base de datos para persistencia de estados de transacciones.

### Archivos Clave
- **`main.tf`**:
  - Configuración de API Gateway, SQS, Lambda y políticas IAM.
  - Integración entre API Gateway y SQS.
- **`variables.tf`**:
  - Personalización de región y entorno.

---

## Alternativa 2: Contenedores (ECS Fargate)

### Arquitectura
- **ECS Fargate**: Contenedores escalables para procesar transacciones.
- **ALB (Application Load Balancer)**: Distribuye tráfico a los contenedores.
- **SQS**: Cola de mensajes para transacciones pendientes.
- **VPC/Subnets**: Redes privadas para ECS y RDS.

### Archivos Clave
- **`main.tf`**:
  - Configuración de VPC, subnets, ECS, ALB y políticas IAM.
  - Seguridad con grupos de seguridad y NAT Gateway.
- **`variables.tf`**:
  - Personalización de región, entorno e imagen de Docker.

---


