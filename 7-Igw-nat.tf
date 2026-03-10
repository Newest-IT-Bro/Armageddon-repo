# Internet gateway
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab1cbs_vpc.id
  tags = merge(
    local.tags,
    { name = "${local.project_name}-igw" }
  )
}

# Nat gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = merge(
    local.tags,
  { name = "${local.project_name}-nat-eip" })
}

# Explanation: NAT is lab1cbs’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_lab1cbs[0].id # NAT in a public subnet
  tags = merge(
    local.tags,
  { name = "${local.project_name}-nat" })

  depends_on = [aws_internet_gateway.lab_igw, aws_route_table.lab1cbs_public_rt]
}
