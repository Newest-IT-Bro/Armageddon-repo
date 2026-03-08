############################################
# Least-Privilege IAM (BONUS A)
############################################

# Explanation: Chewbacca doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "lab1cbs_leastpriv_read_params" {
  name        = "${local.project_name}-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /lab/db/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
        ]
      }
    ]
  })
}

# Explanation: Chewbacca only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "lab1cbs_lp_read_secret01" {
  name        = "${local.project_name}-lp-secrets-read01"
  description = "Least-privilege read for the lab DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.secret_arn_guess
      }
    ]
  })
}

# Explanation: When the Falcon logs scream, this lets Chewbacca ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "lab1cbs_lp_cwlogs01" {
  name        = "${local.project_name}-lp-cwlogs01"
  description = "Least-privilege CloudWatch Logs write for the app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.app_logs.arn}:*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_lp_params01" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.lab1cbs_leastpriv_read_params.arn
}

resource "aws_iam_role_policy_attachment" "attach_lp_secret01" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.lab1cbs_lp_read_secret01.arn
}

resource "aws_iam_role_policy_attachment" "attach_lp_cwlogs01" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.lab1cbs_lp_cwlogs01.arn
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
        "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${var.secrets_manager}*" #Remember add a or your policy will not work
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
  role = aws_iam_role.ec2_role.name

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
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${local.project_name}-rds-app*:*"
      }
    ]
  })
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Explanation: lab1c refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "ec2_role" {
  name = "${local.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

