terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.0.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "aws_caller_identity" "current" {}