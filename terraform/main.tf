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

resource "aws_ecs_service" "platform_lite" {
  name            = "platform-lite-service"
  cluster         = aws_ecs_cluster.platform_lite.id
  desired_count   = 1
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 60
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

  lifecycle {
    ignore_changes = [task_definition]
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

resource "aws_cloudwatch_log_group" "platform_lite" {
  name              = "/ecs/platform-lite-task"
  retention_in_days = 7

  tags = {
    Project = "platform-lite"
  }
}
