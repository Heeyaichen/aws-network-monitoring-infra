terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "ap-south-1"
}
