
############################################
# Bonus G - Bedrock Auto Incident Report Pipeline (SNS -> Lambda -> S3)
############################################

resource "aws_s3_bucket" "lab2_ir_reports_bucket" {
  bucket = "${var.project_name}-ir-reports-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "lab2_ir_reports_lifecycle" {
  bucket = aws_s3_bucket.lab2_ir_reports_bucket.id

  rule {
    id     = "expire-old-reports"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lab2_ir_reports_pab" {
  bucket                  = aws_s3_bucket.lab2_ir_reports_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "lab2_ir_lambda_role" {
  name = "${var.project_name}-ir-lambda-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lab2_ir_lambda_policy01" {
  name = "${var.project_name}-ir-lambda-policy01"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/rds/mysql*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.lab2_ir_reports_bucket.arn,
          "${aws_s3_bucket.lab2_ir_reports_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lab2_ir_lambda_attach" {
  role       = aws_iam_role.lab2_ir_lambda_role.name
  policy_arn = aws_iam_policy.lab2_ir_lambda_policy01.arn
}

resource "aws_iam_role_policy_attachment" "lab2_ir_lambda_basiclogs" {
  role       = aws_iam_role.lab2_ir_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lab2_ir_lambda01" {
  function_name = "${var.project_name}-ir-reporter01"
  role          = aws_iam_role.lab2_ir_lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60

  filename         = "${path.module}/lambda_ir_reporter.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_ir_reporter.zip")


  depends_on = [
    aws_iam_role_policy_attachment.lab2_ir_lambda_attach,
    aws_iam_role_policy_attachment.lab2_ir_lambda_basiclogs
  ]
}