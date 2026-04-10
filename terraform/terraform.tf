terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }

    # TLS provider is not required anymore. See comments
    # in main.tf on ' resource "tls_certificate"
    #
    # tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
  backend "local" {
    path = "../aws-terraform-bootstrap.tfstate"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "projects"
}
