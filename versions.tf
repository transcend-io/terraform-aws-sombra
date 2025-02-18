terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.6.0"
    }
  }
  required_version = ">= 0.13"
}
