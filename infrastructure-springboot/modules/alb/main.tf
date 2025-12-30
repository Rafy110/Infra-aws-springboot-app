# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.app_name}-${var.environment}-alb"
  }
}

# Blue Target Group (for Blue/Green deployment)
resource "aws_lb_target_group" "blue" {
  name        = "${var.app_name}-${var.environment}-blue-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.app_name}-${var.environment}-blue-tg"
  }
}

# Green Target Group (for Blue/Green deployment)
resource "aws_lb_target_group" "green" {
  name        = "${var.app_name}-${var.environment}-green-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.app_name}-${var.environment}-green-tg"
  }
}

# Legacy target group for backward compatibility (points to blue initially)
locals {
  target_group_arn = aws_lb_target_group.blue.arn
}

# ACM Certificate (if domain_name is provided and certificate_arn is not)
resource "aws_acm_certificate" "main" {
  count           = var.domain_name != "" && var.certificate_arn == "" ? 1 : 0
  domain_name     = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-cert"
  }
}

# Use provided certificate ARN or the one we created
locals {
  certificate_arn = var.certificate_arn != "" ? var.certificate_arn : (var.domain_name != "" ? aws_acm_certificate.main[0].arn : "")
}

# HTTP Listener (redirects to HTTPS) - only if certificate exists
resource "aws_lb_listener" "http" {
  count             = local.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol     = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count             = local.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# Fallback HTTP listener if no certificate
resource "aws_lb_listener" "http_fallback" {
  count             = local.certificate_arn == "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

