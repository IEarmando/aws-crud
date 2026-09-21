terraform {
  backend "s3" {
    bucket       = "terraform-state-ec2-lab-141553305029-us-east-1-an"
    key          = "terraform-aws-ec2/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}