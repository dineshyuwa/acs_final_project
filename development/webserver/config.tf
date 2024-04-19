terraform {
  backend "s3" {
    bucket = "acs730-project8-143871234"
    key    = "project/development/webserver/terraform.tfstate"
    region = "us-east-1"
  }
}