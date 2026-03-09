############################################
# Bonus B - Route53 Zone Apex + ALB Access Logs to S3
############################################

############################################
# Route53: Zone Apex (root domain) -> ALB
############################################

# Explanation: The zone apex is the throne room—lab1cbs-growl.com itself should lead to the ALB.
resource "aws_route53_record" "lab1cbs_apex_alias01" {
  zone_id = local.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.lab1cbs_alb.dns_name
    zone_id                = aws_lb.lab1cbs_alb.zone_id
    evaluate_target_health = true
  }
}

############################################
# S3 bucket for ALB access logs
############################################

# Explanation: This bucket is lab1cbs’s log vault—every visitor to the ALB leaves footprints here.
resource "aws_s3_bucket" "lab1cbs_alb_logs_bucket" {
  bucket        = "lab1cbs-alb-logs-961341540291"
  force_destroy = true  # Allows terraform destroy to empty and delete

lifecycle {
   create_before_destroy = true
  }
}

# Disable versioning to allow clean deletion
resource "aws_s3_bucket_versioning" "lab1cbs_alb_logs_versioning" {
  bucket = aws_s3_bucket.lab1cbs_alb_logs_bucket.id

  versioning_configuration {
    status = "Disabled"

    }
}


# Explanation: Block public access—lab1cbs does not publish the ship’s black box to the galaxy.
resource "aws_s3_bucket_public_access_block" "lab1cbs_alb_logs_pab01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.lab1cbs_alb_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explanation: Bucket ownership controls prevent log delivery chaos—lab1cbs likes clean chain-of-custody.
resource "aws_s3_bucket_ownership_controls" "lab1cbs_alb_logs_owner" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.lab1cbs_alb_logs_bucket[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Explanation: TLS-only—lab1cbs growls at plaintext and throws it out an airlock.
resource "aws_s3_bucket_policy" "lab1cbs_alb_logs_policy" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.lab1cbs_alb_logs_bucket[0].id
  # ...policy json...

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBLogDelivery"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.lab1cbs_alb_logs_bucket[0].arn}/lab1cbs_alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowELBLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.lab1cbs_alb_logs_bucket[0].arn
      }
    ]
  })
}

############################################
# Enable ALB access logs (on the ALB resource)
############################################

# Explanation: Turn on access logs—lab1cbs wants receipts when something goes wrong.
# NOTE: This is a skeleton patch: students must merge this into aws_lb.lab1cbs_alb
# by adding/accessing the `access_logs` block. Terraform does not support "partial" blocks.
#
# Add this inside resource "aws_lb" "lab1cbs_alb" { ... } in bonus_b.tf:

# access_logs {
#   bucket  = aws_s3_bucket.lab1cbs_alb_logs_bucket.bucket
#   prefix  = var.alb_access_logs_prefix
#   enabled = var.enable_alb_access_logs
# }
