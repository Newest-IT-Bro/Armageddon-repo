resource "aws_vpc" "lab1cbs_vpc" {
  cidr_block           = "10.237.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
  { name = "${var.project_name}-vpc" })
}