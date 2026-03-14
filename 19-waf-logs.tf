############################################
# Bonus B - WAF Logging (CloudWatch Logs OR S3 OR Firehose)
# One destination per Web ACL, choose via var.waf_log_destination.
############################################

############################################
# CloudWatch Logs destination
############################################
resource "aws_cloudwatch_log_group" "lab2_waf_log_group01" {
  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

  name              = "aws-waf-logs-${var.project_name}-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.project_name}-waf-log-group01"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "lab2_waf_logging01" {
  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.lab2_waf01[0].arn

  log_destination_configs = [
    aws_cloudwatch_log_group.lab2_waf_log_group01[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.lab2_waf01]
}

############################################
# S3 destination
############################################
resource "aws_s3_bucket" "lab2_waf_logs_bucket01" {
  count = var.enable_waf && var.waf_log_destination == "s3" ? 1 : 0

  bucket = "aws-waf-logs-${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-waf-logs-bucket01"
  }
}

resource "aws_s3_bucket_public_access_block" "lab2_waf_logs_pab01" {
  count = var.enable_waf && var.waf_log_destination == "s3" ? 1 : 0

  bucket                  = aws_s3_bucket.lab2_waf_logs_bucket01[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_wafv2_web_acl_logging_configuration" "lab2_waf_logging_s3_01" {
  count = var.enable_waf && var.waf_log_destination == "s3" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.lab2_waf01[0].arn

  log_destination_configs = [
    aws_s3_bucket.lab2_waf_logs_bucket01[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.lab2_waf01]
}
