terraform {
  backend "s3" {
    bucket = "terraform-states-brewery2"
    key    = "ondad/brewery_data_lake_definitive"
    region = "us-east-1"
  }
}