provider "aws" {
  region = "eu-west-2"
}

data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com/"
}
