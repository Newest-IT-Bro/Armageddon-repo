############################################
# Bonus B - Route53 Zone Apex + ALB Access Logs to S3
############################################

############################################
# Route53: Zone Apex (root domain) -> ALB
############################################
/*
# Explanation: The zone apex is the throne room—lab2-growl.com itself should lead to the ALB.
resource "aws_route53_record" "lab2_apex_alias01" {
  zone_id = local.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.lab2_alb.dns_name
    zone_id                = aws_lb.lab2_alb.zone_id
    evaluate_target_health = true
  }
}
*/

############################################
# S3 bucket for ALB access logs
############################################

# Explanation: This bucket is lab2’s log vault—every visitor to the ALB leaves footprints here.
resource "aws_s3_bucket" "lab2_alb_logs_bucket" {
  bucket        = "lab2-alb-logs-961341540291"
  force_destroy = true # Allows terraform destroy to empty and delete
}

# Disable versioning to allow clean deletion
resource "aws_s3_bucket_versioning" "lab2_alb_logs_versioning" {
  bucket = aws_s3_bucket.lab2_alb_logs_bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Explanation: Encrypt logs at rest—lab2 protects the black box with cryptography.
resource "aws_s3_bucket_server_side_encryption_configuration" "lab2_alb_logs_encryption" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.lab2_alb_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Explanation: Block public access—lab2 does not publish the ship’s black box to the galaxy.
resource "aws_s3_bucket_public_access_block" "lab2_alb_logs_pab01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.lab2_alb_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explanation: Bucket ownership controls prevent log delivery chaos—lab2 likes clean chain-of-custody.
resource "aws_s3_bucket_ownership_controls" "lab2_alb_logs_owner" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.lab2_alb_logs_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Explanation: TLS-only—lab2 growls at plaintext and throws it out an airlock.

resource "aws_s3_bucket_policy" "lab2_alb_logs_policy" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.lab2_alb_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.lab2_alb_logs_bucket.bucket}/${var.alb_access_logs_prefix != "" ? "${var.alb_access_logs_prefix}/" : ""}AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.lab2_alb_logs_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.lab2_alb_logs_bucket.bucket}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

############################################
# Enable ALB access logs (on the ALB resource)
############################################

# Explanation: Turn on access logs—lab2 wants receipts when something goes wrong.
# NOTE: This is a skeleton patch: students must merge this into aws_lb.lab2_alb
# by adding/accessing the `access_logs` block. Terraform does not support "partial" blocks.
#
# Add this inside resource "aws_lb" "lab2_alb" { ... } in bonus_b.tf:

# access_logs {
#   bucket  = aws_s3_bucket.lab2_alb_logs_bucket.bucket
#   prefix  = var.alb_access_logs_prefix
#   enabled = var.enable_alb_access_logs
# }
