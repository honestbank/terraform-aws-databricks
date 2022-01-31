resource "aws_s3_bucket_public_access_block" "root_storage_bucket" {
  bucket                  = var.root_bucket
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}




data "databricks_aws_bucket_policy" "this" {
  bucket = var.root_bucket
}

resource "aws_s3_bucket_policy" "root_bucket_policy" {
  bucket = var.root_bucket
  policy = data.databricks_aws_bucket_policy.this.json
}
