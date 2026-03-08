locals {
  project_name      = "lab1cbs"
  vpc_cidr          = "10.237.0.0/16"
  instance_type     = "t3.micro"
  db_instance_class = "db.t3.micro"
  db_name           = "labdb"
  db_username       = "admin"
  my_ip_cidr        = "${chomp(data.http.my_public_ip.response_body)}/32"
  region            = "eu-west-2"
  secret_name       = "lab/rds/mysql"
  /* zone_name         = "passportpookie.click"*/
  /*hosted_zone_id    = "Z09361711HDESSBG6MZ22"*/
  fqdn = "passportpookie.click"
  /* passportpookie_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.passportpookie[0].zone_id: data.aws_route53_zone.passportpookie_existing[0].zone_id*/
  secret_arn_guess   = "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.secrets_manager}/rds/mysql*"
  public_subnet_ids  = aws_subnet.public_lab1cbs[*].id
  private_subnet_ids = aws_subnet.private_lab1cbs[*].id

  interface_endpoints = {
    ssm         = "com.amazonaws.eu-west-2.ssm"
    ec2messages = "com.amazonaws.eu-west-2.ec2messages"
    ssmmessages = "com.amazonaws.eu-west-2.ssmmessages"
    logs        = "com.amazonaws.eu-west-2.logs"
    secrets     = "com.amazonaws.eu-west-2.secretsmanager"
    kms         = "com.amazonaws.eu-west-2.kms"
  }

  gateway_endpoints = {
    s3 = "com.amazonaws.eu-west-2.s3"
  }

  tags = {
    project     = local.project_name
    environment = "lab"
    ManagedBy   = "Terraform"
  }
}



