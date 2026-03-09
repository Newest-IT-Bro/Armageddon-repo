############################################
# Move EC2 into PRIVATE subnet (no public IP)
############################################

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
resource "aws_instance" "lab_ec2" {
  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = local.instance_type
  key_name                    = var.aws_key_pair_name
  subnet_id                   = aws_subnet.private_lab1cbs[0].id 
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # user_data = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true
  user_data                   = file("./scripts/user_data.sh")

  tags = merge(
    local.tags,
  { name = "${local.project_name}-ec2-app" })
}