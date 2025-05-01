/**
 * Main Terraform Configuration
 * - Setup locals variables used across multiple files
 */

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    #https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}


