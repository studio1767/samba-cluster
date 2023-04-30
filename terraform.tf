terraform {  
  required_version = ">= 1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.63"
    }
    wireguard = {
      source = "ojford/wireguard"
      version = "0.2.1+1"
    }
  }
}

provider "wireguard" {}

provider "aws" {
  alias = "region0"
  profile = var.aws_profile0
  region = var.aws_region0
}

provider "aws" {
  alias = "region1"
  profile = var.aws_profile1
  region = var.aws_region1
}

