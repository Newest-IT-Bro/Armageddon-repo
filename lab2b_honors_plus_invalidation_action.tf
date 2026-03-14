############################################
# Lab 2B-Honors+ - Optional invalidation action (run on demand)
############################################

# Explanation: This is lab2’s “break glass” lever — use it sparingly or the bill will bite.
action "aws_cloudfront_create_invalidation" "lab2_invalidate_index01" {
  config {
    distribution_id = aws_cloudfront_distribution.lab2_cf01.id

    paths = ["/static/*"]
  }
}


