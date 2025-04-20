resource "aws_s3_bucket" "brewery-test-files-temp2" {
  bucket        = "brewery-test-files-temp2"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "brewery_temp_test_bucket_lifecycle" {
  bucket = aws_s3_bucket.brewery-test-files-temp2.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    filter {
      object_size_greater_than = 1
    }

    expiration {
      days = 1
    }
  }
}