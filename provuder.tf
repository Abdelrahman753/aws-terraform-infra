terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "aws" {

  alias      = "vpc2"
  region     = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}