######################
# Required Variables #
######################

variable project_id {
  description = <<EOF
  A name to use in resources, such as the name of your company.
  EOF
}

variable vpc_id {
  description = "The ID of the VPC to put this application into"
}

variable ecr_image {
  description = "Url of the ECR repo, including the tag"
  default     = "829095311197.dkr.ecr.eu-west-1.amazonaws.com/sombra:prod"
}

variable desired_count {
  description = "The number of ECS tasks that the service should keep alive"
}

variable public_subnet_ids {
  type        = list(string)
  description = "The subnets the ALB can be placed into"
}

variable private_subnet_ids {
  type        = list(string)
  description = "The subnets the ECS tasks can be placed into"
}

variable private_subnets_cidr_blocks {
  type        = list(string)
  description = "CIDR blocks that an ECS task could be in"
}

variable zone_id {
  description = "The ID of the Route53 hosted zone where the sombra subdomain will be created"
}

variable certificate_arn {
  description = "Arn of the ACM cert that exists on the ALB"
}

variable subdomain {
  description = <<EOF
  The subdomain to create the sombra services at.

  If subdomain is "sombra" and the root_domain is "test.com" then
  the sombra services would be available at "sombra.test.com"
  EOF
}

variable root_domain {
  description = <<EOF
  The root domain to create the sombra services at.

  If subdomain is "sombra" and the root_domain is "test.com" then
  the sombra services would be available at "sombra.test.com"
  EOF
}

variable deploy_env {
  description = "The environment to deploy to, usually dev, staging, or prod"
}

variable data_subject_auth_methods {
  type        = list(string)
  description = "Supported data subject authentication methods"
}

variable employee_auth_methods {
  type        = list(string)
  description = "Supported customer employee authentication methods"
}

variable jwt_ecdsa_key {
  description = <<EOF
  The JSON Web Token asymmetric key for signing Sombra payloads, using the Elliptic
  Curve Digital Signature Algorithm"
  EOF
}

variable tls_config {
  type = object({
    passphrase = string
    cert       = string
    key        = string
  })
  description = "Sombra TLS Support. These values are sensitive."
}

######################
# Optional Variables #
######################

variable cluster_id {
  description = "ID of the ECS cluster this service should run in"
  default = ""
}

variable "alb_access_logs" {
  description = "Map containing access logging configuration for the load balancer."
  type        = map(string)
  default     = {}
}

variable incoming_cidr_range {
  description = <<EOF
  If you want to restrict the IP addresses that can talk to the
  internal sombra service, you can do so with this cidr block.

  Oftentimes, this will be the cidr block of the VPC containing the
  application you are calling the sombra api from.
  EOF
  default     = "0.0.0.0/0"
}

variable use_local_kms {
  default     = true
  description = "When true, local KMS will be used. When false, AWS will be used"
}

variable internal_key_hash {
  default     = ""
  description = "This will override the generated internal key"
}

variable hmac_nonce_key_cycle {
  default     = ""
  description = "Cycled HMAC nonce key (384 bits), held around during a key cycle process for requests made before the cycle"
}

variable key_encryption_base_cycle {
  default     = ""
  description = "Cycled High entropy secret value for local KMS (256 bits)"
}

variable transcend_backend_url {
  default     = "https://api.transcend.io:443"
  description = "URL of Transcend's backend"
}

variable transcend_certificate_common_name {
  default     = "*.transcend.io"
  description = "Transcend's certificate Common NameTranscend's certificate Common Name"
}

variable encrypted_saas_http_methods {
  default     = ["GET"]
  type        = list(string)
  description = "Whitelisted HTTP methods when probing a SaaS tool for valid auth credentials"
}

variable saml_config {
  type = object({
    entrypoint             = string
    issuer                 = string
    cert                   = string
    audience               = string
    accepted_clock_skew_ms = number
  })
  default = {
    entrypoint             = ""
    cert                   = ""
    issuer                 = "transcend"
    audience               = "transcend"
    accepted_clock_skew_ms = 0
  }
  description = <<EOF
  Info about SAML logins, used if SAML is an enabled auth_method.

  __Fields__
  entrypoint: identity provider entrypoint (is required to be spec-compliant when the request is signed)
  issuer: issuer string to supply to identity provider
  cert: the IDP's public signing certificate used to validate the signatures of the incoming SAML Responses
  audience: expected saml response Audience (if not provided, Audience won't be verified)
  acceptedClockSkewMs: Time in milliseconds of skew that is acceptable between client and server when
                       checking OnBefore and NotOnOrAfter assertion condition validity timestamps.
                       Setting to -1 will disable checking these conditions entirely.
  EOF
}

variable oauth_config {
  type = object({
    scopes                      = list(string)
    client_id                   = string
    secret_id                   = string
    get_token_url               = string
    get_core_id_url             = string
    get_core_id_path            = string
    get_profile_url             = string
    get_token_body_redirect_uri = string
    get_profile_path            = string
    get_email_path              = string
    profile_picture_path        = string
    email_is_verified_path      = string
    email_is_verified           = bool
  })
  default = {
    scopes                      = []
    client_id                   = ""
    secret_id                   = ""
    get_token_url               = ""
    get_core_id_url             = ""
    get_core_id_path            = ""
    get_profile_url             = ""
    get_token_body_redirect_uri = ""
    get_profile_path            = ""
    get_email_path              = ""
    profile_picture_path        = ""
    email_is_verified_path      = ""
    email_is_verified           = false
  }
  description = <<EOF
  Info about OAuth logins, used if OAuth is an enabled auth_method.

  The secret_id field is sensitive.
  EOF
}

variable jwt_authentication_public_key {
  default     = ""
  description = "Customer's data subject authentication via JWT public key"
}

variable aws_region {
  description = "The AWS region to deploy resources to"
  default     = "eu-west-1"
}

variable internal_port {
  description = "The port the internal sombra should run on. This is the server that your internal services will have access to."
  default     = 443
}

variable external_port {
  description = "The port the external sombra should run on, this is the server that only Transcend's API talks to."
  default     = 5041
}

variable log_level {
  description = "The level at which logs should go to console: see https://github.com/pinojs/pino"
  default     = "warn"
}

variable use_cloudwatch_logs {
  type        = bool
  description = "If true, a cloudwatch group will be created and written to."
  default     = true
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable log_configuration {
  type = object({
    logDriver = string
    options   = map(string)
  })
  description = <<EOF
  Log configuration options to send to a custom log driver for the container.
  For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html

  This parameter is ignored if use_cloudwatch_logs is true, and a log group will be automatically
  written to.

  Use log_secrets to set extra options here that should be secret, such as API keys for third party loggers.
  EOF
  default     = null
}

variable log_secrets {
  type        = map(string)
  default     = {}
  description = "Used to add extra options to log_configuration.options that should be secret, such as third party API keys"
}

variable extra_container_definitions {
  type        = list(string)
  description = <<EOF
  Extra ECS container definitions to add to the task.

  This can be used to add sidecar containers such as AWS firelens, Datadog agent, etc.

  If you're using the fargate_container_definition module from this
  repo, then each value in the list can be the `json_map` output.
  EOF
  default     = []
}

variable cpu {
  default     = 512
  description = "How much CPU should be allocated to the task?"
}

variable memory {
  default     = 1024
  description = "How much memory should be allocated to the task?"
}

variable extra_task_policy_arns {
  type        = list(string)
  description = <<EOF
  ARNs of any additional IAM Policies you want to attach to the ECS Task.

  This module already comes with policies for doing sombra things like reading
  from KMS and for reading SSM parameters made from var.log_secrets or any
  secret env vars it creates.

  So the only real time you'd need this is if you are sidecaring containers
  using var.extra_container_definitions, and those containers need extra
  permissions.
  EOF
  default     = []
}

variable tags {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
  default     = {}
}

