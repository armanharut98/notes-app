resource "aws_security_group" "alb" {
  name        = "${local.core_name_prefix}-alb"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.core.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.core_name_prefix}-app-alb-sg"
  }
}

resource "aws_lb" "app" {
  name                       = "${local.core_name_prefix}-app-alb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.core_public[*].id

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name = "${local.core_name_prefix}-app-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${local.core_name_prefix}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.core.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${local.core_name_prefix}-app-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
