provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "AOS-Warranty-GitOps"
      ManagedBy = "Terraform"
      Lab       = "true"
    }
  }
}

data "aws_caller_identity" "current" {}
