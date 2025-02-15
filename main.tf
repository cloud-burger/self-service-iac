data "aws_availability_zones" "available" {
  # Do not include local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "cloud-burger-states"
    key    = "prod/iac.tfstate"
    region = "us-east-1"
  }
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.22"
    }
  }
}
