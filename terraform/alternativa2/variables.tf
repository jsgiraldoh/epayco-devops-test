variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (dev, stg, prod)"
  type        = string
  default     = "dev"
}

variable "ecs_image" {
  description = "Imagen de Docker para el contenedor ECS"
  type        = string
  default     = "your-docker-image"
}