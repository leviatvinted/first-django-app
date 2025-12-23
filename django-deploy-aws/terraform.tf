terraform {
    cloud {
      organization = "leviatvinted-org"

      workspaces {
        project = "Learn Terraform"
        name = "learn-terraform-aws-get-started"
      }
    }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }

  required_version = ">= 1.5"
}

