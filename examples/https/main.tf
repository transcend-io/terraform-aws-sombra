# To use the sombra module, you must declare the AWS and Vault providers explicitly
# Your settings will very likely be different here. 
provider "aws" {
  profile = "dev"
  region = "eu-west-1"
}
provider "vault" {
  # You are more than welcome to use real vault credentials here.
  # See https://github.com/hashicorp/terraform-provider-vault/issues/666
  # for an explanation of why a "fake" set of settings is required when using
  # modules that optionally use the vault provider
  address = "https://vault.${local.parent_domain}"
  token   = "not-a-real-token"
  skip_tls_verify = true
  skip_child_token = true
  skip_get_vault_version = true
}

locals {
  subdomain = "https-test"
  # You should pick a hosted zone that is in your AWS Account
  parent_domain = "sombra.dev.trancsend.com"
  # Org URI found on https://app.transcend.io/infrastructure/sombra/sombras
  organization_uri = "<org_uri>"
  sombra_id = "<sombra_id>"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.2"

  name = "sombra-example-https-test-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b"]

  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  public_subnets  = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

data "aws_route53_zone" "this" {
  name = local.parent_domain
}

module "acm" {
  source      = "terraform-aws-modules/acm/aws"
  version     = "~> 2.0"
  zone_id     = data.aws_route53_zone.this.id
  domain_name = "${local.subdomain}.${local.parent_domain}"
}

module "sombra" {
  source  = "transcend-io/sombra/aws"
  version = "1.8.0"

  # General Settings
  deploy_env       = "example"
  project_id       = "example-https"
  organization_uri = local.organization_uri

  # VPC settings
  vpc_id                      = module.vpc.vpc_id
  public_subnet_ids           = module.vpc.public_subnets
  private_subnet_ids          = module.vpc.private_subnets
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  aws_region                  = "eu-west-1"
  use_private_load_balancer   = false

  # DNS Settings
  subdomain       = local.subdomain
  root_domain     = local.parent_domain
  zone_id         = data.aws_route53_zone.this.id
  certificate_arn = module.acm.this_acm_certificate_arn

  # App settings
  data_subject_auth_methods = ["transcend", "session"]
  employee_auth_methods     = ["transcend", "session"]

  # HTTPS Configuration
  desired_count = 1
  tls_config = {
    passphrase = "unsecurePasswordAsAnExample"
    cert = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNNVENDQWJZQ0ZFL056RUZVU201ZUtwQ29BczlNVjdwcnpqYjBNQW9HQ0NxR1NNNDlCQU1DTUh3eEN6QUoKQmdOVkJBWVRBbFZUTVFzd0NRWURWUVFJREFKRFFURVdNQlFHQTFVRUJ3d05VMkZ1SUVaeVlXNWphWE5qYnpFWApNQlVHQTFVRUNnd09WSEpoYm5OalpXNWtJRWx1WXk0eEVqQVFCZ05WQkFNTUNXeHZZMkZzYUc5emRERWJNQmtHCkNTcUdTSWIzRFFFSkFSWU1ZMlZ5ZEhOQWVXOHVZMjl0TUI0WERUSXlNRGd3T1RFME5URTFNRm9YRFRJeU1Ea3cKT0RFME5URTFNRm93ZkRFTE1Ba0dBMVVFQmhNQ1ZWTXhDekFKQmdOVkJBZ01Ba05CTVJZd0ZBWURWUVFIREExVApZVzRnUm5KaGJtTnBjMk52TVJjd0ZRWURWUVFLREE1VWNtRnVjMk5sYm1RZ1NXNWpMakVTTUJBR0ExVUVBd3dKCmJHOWpZV3hvYjNOME1Sc3dHUVlKS29aSWh2Y05BUWtCRmd4alpYSjBjMEI1Ynk1amIyMHdkakFRQmdjcWhrak8KUFFJQkJnVXJnUVFBSWdOaUFBVEY1bWx5YXo0djl0MmF1MDd2WnVLLzdrVzFGTEZHRnZWUDY2VEpnYXAvMDE1WAozdVFtR2NQRndZUUJGSFZHOEFEUFRBb0FmMGt0WnJySTk5Q1FlY1FNR0YvWkRlUW9wc3NsaHdvRThmWjJDbDNpCm9XRnZPOGJkZkZESzJmWHBtS3N3Q2dZSUtvWkl6ajBFQXdJRGFRQXdaZ0l4QUlEZENjUVQ4V2I5c3NqZGhRUTIKdFZCZG5YS283UVlUWnpNL1YyOWlvTWZ4emFYL0ZEaXdvRmNTMzEwNnZISWJVd0l4QU4rWXlDd0tweE8vaGx4VwprK0h3RDNvWWUvS3IwRmxwclpXQlVnb2QwQVhIbXVINzJnQzdaeE9CcG9UcnRDRXNzdz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
    key = "LS0tLS1CRUdJTiBFTkNSWVBURUQgUFJJVkFURSBLRVktLS0tLQpNSUlCRXpCT0Jna3Foa2lHOXcwQkJRMHdRVEFwQmdrcWhraUc5dzBCQlF3d0hBUUlLS2VGRzNidWt1OENBZ2dBCk1Bd0dDQ3FHU0liM0RRSUpCUUF3RkFZSUtvWklodmNOQXdjRUNDUExlQkYvUjhsY0JJSEF2N3pQWHpZZFVPOWUKTWF6dTg4c0doaUsrc2k4M1NueTFvdUZQT21mMkRqZjNqbE11Z3g0NWJVWVhLSitVc0tia1l3YU50d2lEaGxRQgpTZ21mbDBobi9hN2dIQys5OEZEcno0SEFvVEVuWXVWcnVxZXpEVHB1MGxNUnhraFZnUUhPOWJ3bDlZWVpZN3dSCnBDOUVTYmVYeGNhdXhPU2svcUhDdVg0cXl0c0RVM0lITDR1OS8yN3NtU0kyRzdRZjFGNFlobFNicm9uKy9KMzEKcUFrTmlDSUwybFVWdlFGMEdFSHQ5QlBTVHdDdHNvK3RrWmpBNjBhazJQK1d1VEUyYkpuYgotLS0tLUVORCBFTkNSWVBURUQgUFJJVkFURSBLRVktLS0tLQo="
  }
  extra_envs = {

    SOMBRA_ID = local.sombra_id

    # This is just an example of an env you can set, though all the main environment variables
    # can be configured through other terraform variables.
    # SINGLE_TENANT_SYNC_TIMEOUT = "0" # set to 0 to disable single tenant sync timeout
  }

  # The root secrets that you should generate yourself and keep secret
  # See https://docs.transcend.io/docs/security/end-to-end-encryption/deploying-sombra#6.-cycle-your-keys for information on how to generate these values
  jwt_ecdsa_key     = "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1JR2tBZ0VCQkRCT0JkNExXVzNaTkJXOWhyTUJ4YlJUemx0SjZjWitIMm5GM3FybDgwdnpLbG1yMnFkRzU5YTUKOU1vWTJhWTJYWVNnQndZRks0RUVBQ0toWkFOaUFBUTBQOUI5Nm9FaVZhWmo3RnhRWThtM1JaMnRRRkVNaUhaWgpKTXk0NjdBcEJiRFRJZkpHRWh3MjAvcnljS3gxY25CUzRqYk5rdTVLNHh0TlpSMDcwVHNFWkREVmh3Y3kxNWRkCktWaDJGcVZvczkxVjVCSVUyK0xENUpYUGUweUVtM1U9Ci0tLS0tRU5EIEVDIFBSSVZBVEUgS0VZLS0tLS0K"
  internal_key_hash = "wm/mZTcSALaEibJXmhdq8g7lUN19kgXQ4hWgjt3woE8="

  tags = {}
}

output "customer_ingress_url" {
  value = module.sombra.internal_url
}

output "transcend_ingress_url" {
  value = module.sombra.external_url
}