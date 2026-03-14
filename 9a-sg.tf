# Explanation: EC2 SG is lab1c’s bodyguard—only let in what you mean to.
resource "aws_security_group" "ec2_sg" {
  name        = "${local.project_name}-ec2-sg"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.lab2_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lab2_alb_sg.id]
  }

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
  { name = "${local.project_name}-ec2-sg" })
}


# TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
# TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.

resource "aws_security_group" "rds_sg" {
  name        = "${local.project_name}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.lab2_vpc.id

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
  { name = "${local.project_name}-rds-sg" })
}

resource "aws_security_group" "vpce_allow_tls" {
  name        = "${local.project_name}-vpce-allow-tls"
  description = "Allow TLS from inside VPC to interface endpoints"
  vpc_id      = aws_vpc.lab2_vpc.id

  tags = merge(local.tags, {
    Name = "${local.project_name}-vpce-allow-tls"
  })
}

# Ingress: 443 from VPC IPv4 CIDR
resource "aws_vpc_security_group_ingress_rule" "vpce_tls_ipv4" {
  security_group_id = aws_security_group.vpce_allow_tls.id
  cidr_ipv4         = aws_vpc.lab2_vpc.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "TLS from VPC IPv4"
}

# Egress: allow all outbound IPv4
resource "aws_vpc_security_group_egress_rule" "vpce_all_ipv4" {
  security_group_id = aws_security_group.vpce_allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound IPv4"
}
