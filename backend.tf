terraform {
  backend "s3" {
    bucket = "kumpdev-terraform-backend"
    key    = "mc-kumpdev-pvc"
    region = "us-east-1"
  }
}
