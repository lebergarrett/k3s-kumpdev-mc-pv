terraform {
  backend "s3" {
    bucket = "kumpdev-terraform-backend"
    key    = "mc-kumpdev-pv/terraform.tfstate"
    region = "us-east-1"
  }
}
