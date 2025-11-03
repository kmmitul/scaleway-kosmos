terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

  }
  required_version = ">= 1.2.0"
}

provider "scaleway" {
  profile = var.scw_profile
}

provider "aws" {
  profile = var.aws_profile
  region  = "eu-west-3" # Paris
}

provider "google" {
  project = var.gcp_project_id
  region  = "europe-west9" # Paris
}