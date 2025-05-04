terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
  }
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "my-terraform-state-bucket-369369369"
    key            = "aws-network-project-terraform/.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"

  }
}

provider "aws" {
  region = "ap-south-1"
}
