resource "aws_vpc" "lab1c_vpc" {
  cidr_block           = "10.237.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-vpc" }
  )
}

# Public Subnets (3 AZs)
resource "aws_subnet" "public_v2" {
  count                   = 3
  vpc_id                  = aws_vpc.lab1c_vpc.id
  cidr_block              = cidrsubnet("10.237.0.0/16", 8, count.index + 100)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    local.tags,
    { Name = "${var.project_name}-public-subnet-${count.index + 1}" }
  )
}

# Private Subnets (3 AZs)
resource "aws_subnet" "private_v2" {
  count                   = 3
  vpc_id                  = aws_vpc.lab1c_vpc.id
  cidr_block              = cidrsubnet("10.237.0.0/16", 8, count.index + 110)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    local.tags,
    { Name = "${var.project_name}-private-subnet-${count.index + 1}" }
  )
}

# Internet gateway
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab1c_vpc.id
  tags = merge(
    local.tags,
    { Name = "${local.project_name}-igw" }
  )
}

# Nat gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = merge(
    local.tags,
    { Name = "${local.project_name}-nat-eip" }
  )
}

# Explanation: NAT is lab1c’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_v2[0].id # NAT in a public subnet
  tags = merge(
    local.tags,
    { Name = "${local.project_name}-nat" }
  )
  depends_on = [aws_internet_gateway.lab_igw]
}

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab1c_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }
  tags = merge(
    local.tags,
    { Name = "${var.project_name}-public-rt" }
  )
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public_v2[count.index].id
  route_table_id = aws_route_table.public.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab1c_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }
  tags = merge(
    local.tags,
    { Name = "${var.project_name}-private-rt" }
  )
}
# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private_v2[0].id
  route_table_id = aws_route_table.private.id
}
# Explanation: EC2 SG is lab1c’s bodyguard—only let in what you mean to.
resource "aws_security_group" "ec2_sg" {
  name        = "${local.project_name}-ec2-sg"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.lab1c_vpc.id
  dynamic "ingress" {
    for_each = [
      {
        port        = 80
        description = "HTTP from anywhere"
        cidr        = ["0.0.0.0/0"]
      },
      {
        port        = 22
        description = "SSH from my current IP only"
        cidr        = [local.my_ip_cidr]
      }
    ]
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr
      description = ingress.value.description
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    local.tags,
    { Name = "${local.project_name}-ec2-sg" }
  )
}

# TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
# TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.

resource "aws_security_group" "rds_sg" {
  name        = "${local.project_name}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.lab1c_vpc.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-rds-sg" }
  )
}

# Explanation: RDS hides in private subnets like the Rebel base on Hoth—cold, quiet, and not public.
resource "aws_db_subnet_group" "lab_rds" {
  name       = "${local.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private_v2[*].id

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-rds-subnet-group" }
  )
}

# Explanation: This is the holocron of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "lab_rds" {
  identifier             = "${local.project_name}-mysql"
  engine                 = "mysql"
  engine_version         = "8.4"
  instance_class         = local.db_instance_class
  allocated_storage      = 20
  username               = local.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.lab_rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  db_name                = local.db_name

  # TODO: student sets multi_az / backups / monitoring as stretch goals

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-mysql" }
  )
}

# Explanation: lab1c refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "ec2_role" {
  name = "${local.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "secretsmanager_read_policy" {
  name        = "test_policy"
  path        = "/"
  description = "My test policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ReadSpecificSecret",
        "Effect" : "Allow",
        "Action" : ["secretsmanager:GetSecretValue"],
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}secret:${var.secrets_manager}" #Remember add a or your policy will not work
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "example_attachment4" {
  role = aws_iam_role.ec2_role.id
  # Secrets Manager Read Access to allow access to RDS credentials
  policy_arn = aws_iam_policy.secretsmanager_read_policy.arn
}

resource "aws_iam_role_policy" "ssm_policy" {
  name = "${local.project_name}-ssm-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "${local.project_name}-cloudwatch-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStream",
        ]
        Resource = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${local.project_name}-rds-app*"
      }
    ]
  })
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
resource "aws_instance" "lab_ec2" {
  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = local.instance_type
  key_name                    = var.aws_key_pair_name
  subnet_id                   = aws_subnet.public_v2[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # user_data = file("${path.module}/user_data.sh")
  user_data = file("./scripts/user_data.sh")

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-ec2-app" }
  )
}

# Explanation: Parameter Store is lab1c’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.lab_rds.address

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-endpoint" }
  )
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.lab_rds.port)

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param_db_port" }
  )
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "db_name" {
  name  = "/lab/db/name"
  type  = "String"
  value = local.db_name

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-name" }
  )
}

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

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "db_incidents" {
  name = "${local.project_name}-db-incidents-v1"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = "benjam9191@gmail.com"
}


