# Internet gateway
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab2_vpc.id
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

# Explanation: NAT is lab2’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_lab2[0].id # NAT in a public subnet
  tags = merge(
    local.tags,
  { name = "${local.project_name}-nat" })

  depends_on = [aws_internet_gateway.lab_igw, aws_route_table.lab2_public_rt]
}
