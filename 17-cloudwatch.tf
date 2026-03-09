############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################

# Explanation: When the ALB starts throwing 5xx, that’s the Falcon coughing — page the on-call Wookiee.
resource "aws_cloudwatch_metric_alarm" "lab1cbs_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.lab1cbs_alb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.db_incidents.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}

############################################
# CloudWatch Dashboard (Skeleton)
############################################

# Explanation: Dashboards are your cockpit HUD — lab1cbs wants dials, not vibes.
resource "aws_cloudwatch_dashboard" "lab1cbs_dashboard01" {
  dashboard_name = "${var.project_name}-dashboard01"

  # TODO: students can expand widgets; this is a minimal workable skeleton
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.lab1cbs_alb.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", aws_lb.lab1cbs_alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "lab1cbs ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.lab1cbs_alb.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "lab1cbs ALB: Target Response Time"
        }
      }
    ]
  })
}

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${local.project_name}-rds-app"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_metric_filter" "db_connection_errors" {
  name           = "${local.project_name}-db-connection-errors"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  pattern = <<EOF
 ?"pymysql.err.OperationalError" ?"Can't connect" ?"Error" ?"failed" ?"Access denied"
 EOF

  metric_transformation {
    name      = "DBConnectionErrors"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "db-connection_failure" {
  alarm_name          = "${local.project_name}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.db_incidents.arn]

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-db-connection-failure-alarm" }
  )

  depends_on = [
    aws_cloudwatch_log_metric_filter.db_connection_errors,
    aws_sns_topic.db_incidents
  ]
}