############################################
# Security Group: ALB
############################################
resource "aws_security_group" "lab2_alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.lab2_vpc.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Inbound 80 from anywhere
resource "aws_security_group_rule" "alb_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.lab2_alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Inbound 443 from anywhere
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.lab2_alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Outbound only to EC2 app port (80) on the EC2 SG
resource "aws_security_group_rule" "alb_egress_to_ec2_http" {
  type                     = "egress"
  security_group_id        = aws_security_group.lab2_alb_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
}

/*# Allow ALB -> EC2 on app port (80)
resource "aws_security_group_rule" "lab2_ec2_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lab2_alb_sg.id
}
*/

############################################
# Application Load Balancer
############################################
resource "aws_lb" "lab2_alb" {
  name               = "lab2-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.lab2_alb_sg.id]
  subnets         = local.public_subnet_ids

  enable_deletion_protection = false

  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs ? [1] : []
    content {
      bucket  = aws_s3_bucket.lab2_alb_logs_bucket.bucket
      prefix  = var.alb_access_logs_prefix
      enabled = var.enable_alb_access_logs
    }
  }

  depends_on = [
    aws_s3_bucket.lab2_alb_logs_bucket,
    aws_s3_bucket_public_access_block.lab2_alb_logs_pab01,
    aws_s3_bucket_ownership_controls.lab2_alb_logs_owner,
    aws_s3_bucket_policy.lab2_alb_logs_policy
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

############################################
# ACM Certificate (TLS) for app.passportpookie.click (no http://)
############################################
resource "aws_acm_certificate" "lab2_acm_cert" {
  domain_name               = local.fqdn
  subject_alternative_names = [local.app_subdomain]
  validation_method         = var.certificate_validation_method

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-acm-cert"
  }
}

############################################
# ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
############################################
/*
resource "aws_lb_listener" "lab2_http_listener" {
  load_balancer_arn = aws_lb.lab2_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
*/

resource "aws_lb_listener" "lab2_https_listener" {
  load_balancer_arn = aws_lb.lab2_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # If validation exists, use it; otherwise use the cert ARN (apply will still require it to be ISSUED).
  certificate_arn = try(
    aws_acm_certificate_validation.lab2_acm_validation.certificate_arn,
    aws_acm_certificate.lab2_acm_cert.arn
  )

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab2_tg01.arn
  }
}

