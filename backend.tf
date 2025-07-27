terraform {
  backend "s3" {
    bucket = "terrakube-terraform-state-bucket"
    key    = "state/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
