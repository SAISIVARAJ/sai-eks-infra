terraform {
  backend "s3" {
    bucket         = "sai-terraform-state-034859016615"
    key            = "network-layer/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
