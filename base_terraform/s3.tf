resource "aws_s3_bucket" "brewery-test-files-temp" {
  bucket = "brewery-test-files-temp2"
}

resource "aws_s3_bucket_lifecycle_configuration" "brewery_temp_test_bucket_lifecycle" {
  bucket = aws_s3_bucket.brewery-test-files-temp.id

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