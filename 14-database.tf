# Explanation: This is the holocron of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "lab_rds" {
  identifier                          = "${local.project_name}-rds"
  engine                              = "mysql"
  engine_version                      = "8.4.7"
  instance_class                      = local.db_instance_class
  allocated_storage                   = 20
  username                            = "admin"
  password                            = random_password.db_password.result
  db_subnet_group_name                = aws_db_subnet_group.lab_rds.name
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]
  publicly_accessible                 = false
  skip_final_snapshot                 = true
  multi_az                            = false
  db_name                             = local.db_name
  iam_database_authentication_enabled = true
    # TODO: student sets multi_az / backups / monitoring as stretch goals

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-mysql" }
  )
}
