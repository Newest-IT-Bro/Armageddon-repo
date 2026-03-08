data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}


data "http" "my_public-ip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_region" "current" {}

data "aws_elb_service_account" "main" {}


variable "aws_region" {
  description = "AWS Region for the lab1c fleet to patrol."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Same prefix name for all resources."
  type        = string
  default     = "lab1cbs"
}

variable "aws_key_pair_name" {
  description = "Name of the keypair to use for EC2 instances."
  type        = string
  default     = "ec2-lab-app"
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "secrets_manager" {
  description = "secrets Manager secret name for DB credentials."
  type        = string
  default     = "lab/rds/mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "labdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin" # TODO: student supplies
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "WATER&oil92**" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "benjam9191@gmail.com" # TODO: student supplies
}
