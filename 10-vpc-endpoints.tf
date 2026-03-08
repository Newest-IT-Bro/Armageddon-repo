
############################################
# VPC Endpoint - S3 (Gateway)
############################################

# Explanation: S3 is the supply depot—without this, your private world starves (updates, artifacts, logs).
resource "aws_vpc_endpoint" "gateway" {
  vpc_id            = aws_vpc.lab1cbs_vpc.id
  service_name      = "com.amazonaws.eu-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.lab1cbs_private_rt.id]

  tags = merge(local.tags, { name = "${local.project_name}-vpce-s3" })
}

############################################
# VPC Endpoints - SSM (Interface)
############################################

# Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.lab1cbs_vpc.id
  service_name        = "com.amazonaws.eu-west-2.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids          = local.private_subnet_ids  
  security_group_ids  = [aws_security_group.vpce_allow_tls.id]

  tags = merge(
    local.tags,
  { name = "${local.project_name}-vpce-ssm" })
}

# Explanation: ec2messages is the Wookiee messenger—SSM sessions won’t work without it.
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.lab1cbs_vpc.id
  service_name        = "com.amazonaws.eu-west-2.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids          = local.private_subnet_ids  
  security_group_ids  = [aws_security_group.vpce_allow_tls.id]

  tags = merge(
    local.tags,
  { name = "${local.project_name}-vpce-ec2messages" })
}

# Explanation: ssmmessages is the holonet channel—Session Manager needs it to talk back.
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.lab1cbs_vpc.id
  service_name        = "com.amazonaws.eu-west-2.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids 
  security_group_ids = [aws_security_group.vpce_allow_tls.id]

  tags = merge(
    local.tags,
  { name = "${local.project_name}-vpce-ssmmessages" })
}

############################################
# VPC Endpoint - CloudWatch Logs (Interface)
############################################

# Explanation: CloudWatch Logs is the ship’s black box—Chewbacca wants crash data, always.
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.lab1cbs_vpc.id
  service_name        = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_subnet_ids 
  security_group_ids  = [aws_security_group.vpce_allow_tls.id]

  tags = merge(
    local.tags,
  { name = "${local.project_name}-vpce-logs" })
}

############################################
# VPC Endpoint - Secrets Manager (Interface)
############################################

# Explanation: Secrets Manager is the locked vault—Chewbacca doesn’t put passwords on sticky notes.
resource "aws_vpc_endpoint" "secrets" {
  vpc_id              = aws_vpc.lab1cbs_vpc.id
  service_name        = "com.amazonaws.eu-west-2.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_subnet_ids  
  security_group_ids  = [aws_security_group.vpce_allow_tls.id]

  tags = merge(
    local.tags,
  { name = "${local.project_name}-vpce-secrets" })
}

############################################
# VPC Endpoint - KMS (Interface)
############################################

# Explanation: KMS is the encryption kyber crystal—Chewbacca prefers locked doors AND locked safes.
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.lab1cbs_vpc.id
  service_name        = "com.amazonaws.eu-west-2.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_subnet_ids 
  security_group_ids  = [aws_security_group.vpce_allow_tls.id]

  tags = merge(
    local.tags,
  { name = "${local.project_name}-vpce-kms" })
}