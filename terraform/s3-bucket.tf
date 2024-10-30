# S3 Bucket for Static Content
resource "aws_s3_bucket" "static_content" {
  bucket = lower("s3-static-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  tags = var.aws_resource_tags
}
# S3 bucket owner controls
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.static_content.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.static_content.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.static_content.id
  acl    = "public-read"
}

# Upload all files from the 'static' directory to S3
resource "aws_s3_object" "static_files" {
  for_each = { for file in local.static_files : file => file }
  bucket = aws_s3_bucket.static_content.bucket
  key    = "static/${each.value}"                     # S3 key, the file path in S3
  source = "${local.static_folder_root_path}/${each.value}"  # The local file to upload
  content_type = contains(split(".", each.value),"css") ? "text/css" : "application/octet-stream"
  acl    = "public-read"
}
