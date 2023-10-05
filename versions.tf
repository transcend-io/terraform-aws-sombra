terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    # We cannot use versions 3.16.0 or higher due to this regression:
    # https://github.com/hashicorp/terraform-provider-vault/issues/1907
    vault = {
      source = "hashicorp/vault"
      version = "< 3.16.0"
    }
  }
  required_version = ">= 0.13"
}
