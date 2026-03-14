# Public Subnets (3 AZs)
resource "aws_subnet" "public_lab2" {
  count                   = 3
  vpc_id                  = aws_vpc.lab2_vpc.id
  cidr_block              = cidrsubnet("10.237.0.0/16", 8, count.index + 100)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    local.tags, {
  Name = "${var.project_name}-public_lab2-${count.index + 1}" })
}

# Private Subnets (3 AZs)
resource "aws_subnet" "private_lab2" {
  count                   = 3
  vpc_id                  = aws_vpc.lab2_vpc.id
  cidr_block              = cidrsubnet("10.237.0.0/16", 8, count.index + 110)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.tags, {
  Name = "${var.project_name}-private_lab2-${count.index + 1}" })
}

# Explanation: RDS hides in private subnets like the Rebel base on Hoth—cold, quiet, and not public.
resource "aws_db_subnet_group" "lab_rds" {
  name       = "${local.project_name}-rds-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-rds-subnet-group" }
  )
}