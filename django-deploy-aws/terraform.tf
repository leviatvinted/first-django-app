terraform {
  cloud {
    organization = "leviatvinted-org"

    workspaces {
      project = "First Django App"
      name    = "first-django-app"
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

