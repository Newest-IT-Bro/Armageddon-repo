terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}


data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com/"
}


# Main provider for the ALB and other resources

# CloudFront requires ACM certificates to be in us-east-1
# If your ALB is in another region, you need a separate provider
