# Explanation: outputs are your mission report—what got built and where to find it.

output "application_url" {
  value = <<EOT
Home: http://${aws_instance.lab_ec2.public_ip}/
initalize DB: "http://${aws_instance.lab_ec2.public_ip}/init
1st note (GET): "http://${aws_instance.lab_ec2.public_ip}/add?note=first_note
2nd note (GET):http://${aws_instance.lab_ec2.public_ip}/add?note=bluebook_HVM_KS
3rd note (GET): http://${aws_instance.lab_ec2.public_ip}/add?note=thick_asian_women_only
4th note (GET):http://${aws_instance.lab_ec2.public_ip}/add?note=lab1c_successful
List: http://${aws_instance.lab_ec2.public_ip}/list
EOT
}

output "aws_vpc" {
  value = aws_vpc.lab1c_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_v2[0].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_v2[0].id
}

output "ec2_instance" {
  value = aws_instance.lab_ec2.public_ip
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
