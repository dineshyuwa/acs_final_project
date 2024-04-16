terraform {
  backend "s3" {
    bucket = "acs730-project-143871234"
    key    = "project/network/terraform.tfstate"
    region = "us-east-1"
  }
}