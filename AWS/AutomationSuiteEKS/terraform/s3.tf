/**
  * Terraform Variables
  * This file contains all variables used in the Terraform configuration
  */


resource "aws_s3_bucket" "automation_suite_common" {
  bucket        = var.s3_bucket_name
  force_destroy = var.s3_force_destroy
  tags = merge(
    var.tags,
    {
      Name = var.s3_bucket_name
    }
  )
}

resource "aws_s3_bucket_public_access_block" "automation_suite_common" {
  bucket                  = aws_s3_bucket.automation_suite_common.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "automation_suite_common" {
  bucket = aws_s3_bucket.automation_suite_common.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "GET", "PUT", "HEAD", "DELETE"]
    allowed_origins = var.s3_cors_allowed_origins
    expose_headers  = ["x-amz-server-side-encryption", "x-amz-request-id", "x-amz-id-2", "etag"]
    max_age_seconds = 3000
  }
}

data "template_file" "automation_suite_common_s3_iam_policy" {
  template = file("${path.module}/template/s3_common_bucket_policy.tftpl")
  vars = {
    s3_bucket_arn = aws_s3_bucket.automation_suite_common.arn
  }
}

resource "aws_iam_policy" "automation_suite_common" {
  name        = "${var.s3_bucket_name}-policy"
  description = "Policy for S3 bucket ${var.s3_bucket_name}"
  policy      = data.template_file.automation_suite_common_s3_iam_policy.rendered
  tags = merge(
    var.tags,
    {
      Name = "${var.s3_bucket_name}-policy"
    }
  )
}

output "s3_common_bucket_arn" {
  description = "The ARN of the common S3 bucket"
  value       = aws_s3_bucket.automation_suite_common.arn
}
output "s3_common_bucket_id" {
  description = "The ID of the common S3 bucket"
  value       = aws_s3_bucket.automation_suite_common.id
}

