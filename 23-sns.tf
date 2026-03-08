# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
# SNS topic

resource "aws_sns_topic" "db_incidents" {
  name = "${local.project_name}-db-incidents-v1"
  tags = local.tags
}

# Email subscription
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = "benjam9191@gmail.com"
}

/*
# SNS -> Lambda subscription (use the db_incidents topic you actually created)
resource "aws_sns_topic_subscription" "lab1cbs_ir_lambda_sub" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lab1cbs_ir_lambda.arn
}


# Allow SNS to invoke Lambda (source_arn must be the same topic)
resource "aws_lambda_permission" "lab1cbs_allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lab1cbs_ir_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.db_incidents.arn
}
*/

# Output report bucket (must exist with this exact name)
output "lab1cbs_ir_reports_bucket" {
  value = aws_s3_bucket.lab1cbs_alb_logs_bucket.bucket
}