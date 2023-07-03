terraform {
  backend "s3" {
    bucket = "tf-states-bucket-fr"
    key    = "terraform/states/api-gw-eventbridge"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}
