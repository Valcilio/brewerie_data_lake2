terraform {
  backend "s3" {
    bucket = "terraform-states-brewery2"
    key    = "ondad/brewery_data_lake"
    region = "us-east-1"
  }
}