# Explanation: Public route table = “open lanes” to the galaxy via IGW.
############################################
# Public route table
############################################
resource "aws_route_table" "lab1cbs_public_rt" {
  vpc_id = aws_vpc.lab1cbs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-public-rt" }
  )
}

# Attach ALL public subnets to the public RT
resource "aws_route_table_association" "lab1cbs_public_assoc" {
  count          = length(local.private_subnet_ids)
  subnet_id      = local.public_subnet_ids[count.index]
  route_table_id = aws_route_table.lab1cbs_public_rt.id
}

############################################
# Private route table
############################################
resource "aws_route_table" "lab1cbs_private_rt" {
  vpc_id = aws_vpc.lab1cbs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-private-rt" }
  )
}

# Attach ALL private subnets to the private RT
resource "aws_route_table_association" "lab1cbs_private_assoc" {
  count          = length(local.private_subnet_ids)
  subnet_id      = local.private_subnet_ids[count.index]
  route_table_id = aws_route_table.lab1cbs_private_rt.id
}