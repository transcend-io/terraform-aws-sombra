# To use the sombra module, you must declare the AWS provider explicitly
# Your settings may be different here. 
provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.2"

  name = "sombra-example-test-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b"]

  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  public_subnets  = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "sombra" {
  source  = "transcend-io/sombra/aws"
  version = "2.0.0"

  # General Settings
  organization_uri              = "<FILL_ME_IN>"
  sombra_id                     = "<FILL_ME_IN>"
  transcend_backend_url         = "<FILL_ME_IN>"
  sombra_reverse_tunnel_api_key = "<FILL_ME_IN>"

  # VPC settings
  vpc_id                      = module.vpc.vpc_id
  public_subnet_ids           = module.vpc.public_subnets
  private_subnet_ids          = module.vpc.private_subnets
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  aws_region                  = "eu-west-1"

  desired_count = 1

  # The root secrets that you should generate yourself and keep secret
  # Can be generated via: `openssl ecparam -genkey -name secp384r1 -noout | (base64 --wrap=0 2>/dev/null || base64 -b 0)`
  # This can come from a secret store like AWS Secrets Manager or Vault
  # See our guide for dynamically loading secrets from vault here: https://docs.transcend.io/docs/articles/security/end-to-end-encryption/hashicorp-vault-secret-fetching
  jwt_ecdsa_key     = "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1JR2tBZ0VCQkRCT0JkNExXVzNaTkJXOWhyTUJ4YlJUemx0SjZjWitIMm5GM3FybDgwdnpLbG1yMnFkRzU5YTUKOU1vWTJhWTJYWVNnQndZRks0RUVBQ0toWkFOaUFBUTBQOUI5Nm9FaVZhWmo3RnhRWThtM1JaMnRRRkVNaUhaWgpKTXk0NjdBcEJiRFRJZkpHRWh3MjAvcnljS3gxY25CUzRqYk5rdTVLNHh0TlpSMDcwVHNFWkREVmh3Y3kxNWRkCktWaDJGcVZvczkxVjVCSVUyK0xENUpYUGUweUVtM1U9Ci0tLS0tRU5EIEVDIFBSSVZBVEUgS0VZLS0tLS0K"
}