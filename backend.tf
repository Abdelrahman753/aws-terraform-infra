terraform {
  backend "s3" {
    bucket = "nti-state-bucket"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}