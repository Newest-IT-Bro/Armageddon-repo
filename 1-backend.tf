terraform {
  backend "s3" {
    bucket = "terraform-state-961341540291-eu-central-1"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}