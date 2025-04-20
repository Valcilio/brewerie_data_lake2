resource "aws_s3_bucket" "brewery-bronze-layer" {
  bucket        = "brewery-bronze-layer2"
  force_destroy = true
}

resource "aws_s3_bucket" "brewery-silver-layer" {
  bucket        = "brewery-silver-layer2"
  force_destroy = true
}

resource "aws_s3_bucket" "brewery-gold-layer" {
  bucket        = "brewery-gold-layer2"
  force_destroy = true
}

resource "aws_s3_bucket" "athena_outputs" {
  bucket        = "brewery-athena-outputs2"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "brewery_athena_outputs_lifecycle" {
  bucket = aws_s3_bucket.athena_outputs.id

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

resource "aws_s3_bucket_lifecycle_configuration" "brewery_bronze_layer_bucket_lifecycle" {
  bucket = aws_s3_bucket.brewery-bronze-layer.id

  rule {
    id     = "transite-to-glacier"
    status = "Enabled"

    filter {
      object_size_greater_than = 1
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "brewery_silver_layer_bucket_lifecycle" {
  bucket = aws_s3_bucket.brewery-silver-layer.id

  rule {
    id     = "transite-to-glacier"
    status = "Enabled"

    filter {
      object_size_greater_than = 1
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}