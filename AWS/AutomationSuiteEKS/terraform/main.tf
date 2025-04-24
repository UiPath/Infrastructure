/**
 * Main Terraform Configuration
 * - Setup locals variables used across multiple files
 */

provider "aws" {
  region = var.aws_region
}


