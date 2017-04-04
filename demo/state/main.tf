# terrafrom init

terraform {
  backend "s3" {
    bucket = "burdotnet-terraform-state"
    key    = "meetup/demo/state"
    region = "us-east-1"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "burdotnet-bucket-o-chicken"
}
