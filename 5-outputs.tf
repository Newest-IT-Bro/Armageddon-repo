# Explanation: outputs are your mission report—what got built and where to find it.


output "application_urls" {
  description = "URLs to test deployed application through the ALB"
  value = <<EOT
Home           : https://${aws_lb.lab1cbs_alb.dns_name}/
Initialize DB  : https://${aws_lb.lab1cbs_alb.dns_name}/init
1st note (GET) : https://${aws_lb.lab1cbs_alb.dns_name}/add?note=first_note
2nd note (GET) : https://${aws_lb.lab1cbs_alb.dns_name}/add?note=blue_book_gentlemen
3rd note (GET) : https://${aws_lb.lab1cbs_alb.dns_name}/add?note=this_is_200k_work
4th note (GET) : https://${aws_lb.lab1cbs_alb.dns_name}/add?note=a_passport_is_freedom_papers
5th note (GET) : https://${aws_lb.lab1cbs_alb.dns_name}/add?note=lab_1c_is_a_success
List notes     : https://${aws_lb.lab1cbs_alb.dns_name}/list
EOT
}



output "aws_vpc" {
  value = aws_vpc.lab1cbs_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_lab1cbs[*].id 
}

output "private_subnet_ids" {
  value = aws_subnet.private_lab1cbs[*].id 
}

output "db_username" {
  value = aws_db_instance.lab_rds.username
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.db_creds.name
}

output "rds_endpoint" {
  value = aws_db_instance.lab_rds.endpoint
}

output "sns_topic_arn" {
  value = aws_sns_topic.db_incidents.arn
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.app_logs.name
}
# Explanation: These outputs prove lab1cbs built private hyperspace lanes (endpoints) instead of public chaos.
output "vpce_ssm" {
  value = aws_vpc_endpoint.ssm.id
}

output "vpce_logs" {
  value = aws_vpc_endpoint.logs.id
}

output "vpce_secrets" {
  value = aws_vpc_endpoint.secrets.id
}

output "vpce_s3" {
  value = aws_vpc_endpoint.gateway.id
}

output "ec2_private_ip" {
  value = aws_instance.lab_ec2.private_ip
}

# Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
output "alb_dns_name" {
  value = aws_lb.lab1cbs_alb.dns_name
}

output "lab1cbs_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

output "target_group_arn" {
  value = aws_lb_target_group.lab1cbs_tg01.arn
}

output "acm_cert_arn" {
  value = aws_acm_certificate.lab1cbs_acm_cert.arn
}

output "waf_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.lab1cbs_waf01[0].arn : null
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.lab1cbs_dashboard01.dashboard_name
}

output "lab1cbs_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"

}

output "lab1cbs_waf_log_destination" {
  value = var.waf_log_destination
}

output "lab1cbs_waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.lab1cbs_waf_log_group01[0].name : null
}

output "lab1cbs_waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.lab1cbs_waf_logs_bucket01[0].bucket : null
}

output "aws_lambda_function" {
  value = aws_lambda_function.lab1cbs_ir_lambda01.function_name
}