provider "aws" {
  region = var.aws_region
}

# Crear una VPC
resource "aws_vpc" "vpc_payments" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-payments-${var.environment}"
  }
}

# Crear subnets públicas
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.vpc_payments.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "subnet-public-payments-${var.environment}-az1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.vpc_payments.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "subnet-public-payments-${var.environment}-az2"
  }
}

# Crear subnets privadas
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc_payments.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "subnet-private-payments-${var.environment}-az1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc_payments.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "subnet-private-payments-${var.environment}-az2"
  }
}

# Crear un Internet Gateway
resource "aws_internet_gateway" "igw_payments" {
  vpc_id = aws_vpc.vpc_payments.id
  tags = {
    Name = "igw-payments-${var.environment}"
  }
}

# Crear una tabla de rutas pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_payments.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_payments.id
  }

  tags = {
    Name = "rt-public-payments-${var.environment}"
  }
}

# Asociar subnets públicas a la tabla de rutas pública
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Crear un NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "nat-payments-${var.environment}"
  }
}

# Crear una tabla de rutas privada
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_payments.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "rt-private-payments-${var.environment}"
  }
}

# Asociar subnets privadas a la tabla de rutas privada
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Crear un clúster ECS
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster-payments-${var.environment}"
}

# Crear una definición de tarea ECS
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "ecs-task-payments-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "payment-processor"
      image     = var.ecs_image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "QUEUE_URL"
          value = aws_sqs_queue.transaction_queue.url
        }
      ]
    }
  ])
}

# Crear un servicio ECS
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service-payments-${var.environment}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "payment-processor"
    container_port   = 80
  }
}

# Crear un Application Load Balancer (ALB)
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb-payments-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

# Crear un grupo de destino para el ALB
resource "aws_lb_target_group" "ecs_tg" {
  name     = "ecs-tg-payments-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_payments.id
}

# Crear un listener para el ALB
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# Crear una cola SQS
resource "aws_sqs_queue" "transaction_queue" {
  name = "transaction-queue-${var.environment}"
}

# Crear un rol de ejecución para ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Crear una política para el rol de ejecución de ECS
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecs-task-execution-policy-${var.environment}"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.transaction_queue.arn
      }
    ]
  })
}

# Crear un grupo de seguridad para ECS
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg-payments-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.vpc_payments.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Crear un grupo de seguridad para el ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-payments-${var.environment}"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc_payments.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}