locals {
  services = {
    platform_lite = {
      path = "/api/*"
      port = 4000
    }
    orders = {
      path = "/orders*"
      port = 4000
    }
  }
}

resource "aws_ecs_cluster" "platform_lite" {
  name = "platform-lite-cluster"

  tags = {
    Project = "platform-lite"
    Env     = "dev"
  }
}

resource "aws_ecr_repository" "services" {
  for_each = local.services

  name = replace(each.key, "_", "-")

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = each.key
    Env     = "dev"
  }
}

module "services" {
  for_each = local.services

  source = "./modules/ecs-service"

  service_name     = "${replace(each.key, "_", "-")}-service"
  cluster_id       = aws_ecs_cluster.platform_lite.id
  subnets          = [
    "subnet-0cd00ef8dda71af31",
    "subnet-0d7558e1222c6c6d5",
    "subnet-09f45433906dbd8ba"
  ]
  security_groups  = ["sg-0bda7e59c0eed1582"]

  target_group_arn = aws_lb_target_group.services[each.key].arn
  container_name   = "platform-lite-container"
  container_port   = each.value.port

  task_definition  = "platform-lite-task"
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


resource "aws_lb_target_group" "services" {
  for_each = local.services
  name = "${replace(each.key, "_", "-")}-tg"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = "vpc-0a1d0b31ff1d3cb8b"

  target_type = "ip"

  health_check {
    path     = "/health"
    port     = tostring(each.value.port)
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_listener" "platform_lite" {
  load_balancer_arn = aws_lb.platform_lite.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["platform_lite"].arn
  }
}

resource "aws_lb_listener_rule" "services" {
  for_each = local.services

  listener_arn = aws_lb_listener.platform_lite.arn
  priority = 100 + tonumber(index(sort(keys(local.services)), each.key))

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }
}

resource "aws_cloudwatch_log_group" "platform_lite" {
  name              = "/ecs/platform-lite-task"
  retention_in_days = 7

  tags = {
    Project = "platform-lite"
  }
}


resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "platform-lite-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.platform_lite.name
    ServiceName = "platform-lite-service"
  }

  alarm_description = "Triggered when CPU > 70%"
}


resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "platform-lite-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.platform_lite.name
    ServiceName = "platform-lite-service"
  }

  alarm_description = "Triggered when Memory > 70%"
}

resource "aws_appautoscaling_target" "ecs" {
  for_each = local.services

  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.platform_lite.name}/${replace(each.key, "_", "-")}-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = local.services

  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 60
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}


resource "aws_appautoscaling_policy" "memory" {
  for_each = local.services

  name               = "${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}