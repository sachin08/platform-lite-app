resource "aws_ecs_cluster" "platform_lite" {
  name = "platform-lite-cluster"

  tags = {
    Project = "platform-lite"
    Env     = "dev"
  }
}

resource "aws_ecr_repository" "platform_lite" {
  name = "platform-lite-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "platform-lite"
    Env     = "dev"
  }
}

resource "aws_ecs_task_definition" "platform_lite" {
  family                   = "platform-lite-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::684651436668:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "platform-lite-container"
      image     = "nginx:latest"  # temporary placeholder ✅ just to create structure. CI/CD will later override image.
      essential = true

      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
        }
      ]

      environment = [
        {
          name  = "PORT"
          value = "4000"
        },
        {
          name  = "APP_MESSAGE"
          value = "Hello from Terraform 🚀"
        }
      ]
    }
  ])

# meaning of below lifecycle - “Do NOT touch container config — CI/CD owns this”

lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "platform_lite" {
  name            = "platform-lite-service"
  cluster         = aws_ecs_cluster.platform_lite.id
  task_definition = aws_ecs_task_definition.platform_lite.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0cd00ef8dda71af31", "subnet-0d7558e1222c6c6d5", "subnet-09f45433906dbd8ba"]  # replace ✅
    assign_public_ip = true

    security_groups = ["sg-0bda7e59c0eed1582"]  # existing SG ✅
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.platform_lite.arn
    container_name   = "platform-lite-container"
    container_port   = 4000
  }
}


resource "aws_lb" "platform_lite" {
  name               = "platform-lite-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0bda7e59c0eed1582"]   # reuse your existing SG ✅
  subnets            = ["subnet-0cd00ef8dda71af31", "subnet-0d7558e1222c6c6d5", "subnet-09f45433906dbd8ba"]  # same as ECS ✅

  tags = {
    Project = "platform-lite"
  }
}


resource "aws_lb_target_group" "platform_lite" {
  name     = "platform-lite-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = "vpc-0a1d0b31ff1d3cb8b"   # ✅ get from AWS console

  target_type = "ip"

  health_check {
    path                = "/health"
    port                = "4000"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "platform_lite" {
  load_balancer_arn = aws_lb.platform_lite.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.platform_lite.arn
  }
}