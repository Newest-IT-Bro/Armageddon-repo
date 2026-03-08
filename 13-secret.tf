# Explanation: Secrets Manager is lab1c’s locked holster—credentials go here, not in code.
resource "aws_secretsmanager_secret" "db_creds" {
  name = var.secrets_manager
  tags = local.tags
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    username = local.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.lab_rds.address
    port     = 3306
    dbname   = local.db_name
  })
}


