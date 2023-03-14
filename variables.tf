######################
# Required Variables #
######################

variable "project_id" {
  description = "A name to use in resources, such as the name of your company."
}

variable "organization_uri" {
  description = "The unique URI for you organization from Transcend."
}

variable "vpc_id" {
  description = "The ID of the VPC to put this application into"
}

variable "ecr_image" {
  description = "Url of the ECR repo, including the tag"
  default     = "829095311197.dkr.ecr.eu-west-1.amazonaws.com/sombra:prod"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The subnets the ALB can be placed into"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The subnets the ECS tasks can be placed into, as well as the internal load balancer if desired"
}

variable "private_subnets_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks that an ECS task could be in"
}

variable "zone_id" {
  description = "The ID of the Route53 hosted zone where the public sombra subdomain will be created"
}

variable "certificate_arn" {
  description = "Arn of the ACM cert that exists on the ALB"
}

variable "subdomain" {
  description = <<EOF
  The subdomain to create the sombra services at.

  If subdomain is "sombra" and the root_domain is "test.com" then
  the sombra services would be available at "sombra.test.com"
  EOF
}

variable "root_domain" {
  description = <<EOF
  The root domain to create the sombra services at.

  If subdomain is "sombra" and the root_domain is "test.com" then
  the sombra services would be available at "sombra.test.com"
  EOF
}

variable "deploy_env" {
  description = "The environment to deploy to, usually dev, staging, or prod"
}

variable "data_subject_auth_methods" {
  type        = list(string)
  description = "Supported data subject authentication methods"
}

variable "employee_auth_methods" {
  type        = list(string)
  description = "Supported customer employee authentication methods"
}

variable "tls_config" {
  type = object({
    passphrase = string
    cert       = string
    key        = string
  })
  default = {
    passphrase = null
    cert       = null
    key        = null
  }
  description = <<EOF
  Sombra TLS Support. These values are sensitive, and should be kept secret.

  We support quite a few options for this:
  - Not configuring TLS at all, by leaving this variable empty. This is not recommended,
    but is the easiest to setup. If you choose to go this route, you will rely on the TLS termination
    at the load balancer only, and your communication from the ALB -> sombra instances will be unencrypted
    inside your VPC.
  - Adding a cert and key without a passphrase. To do this, add your cert and key here (as base64 encoded values)
    and set the passphrase to either `null` or the empty string. This approach works well for those using the
    `tls` terraform provider for generating certs.
  - Adding a cert with an encoded key with the passphrase to unlock it. To do this, you'll need to manage the certs
    fully on your own, but you can add the certs here as base64 encoded values (passphrase in plaintext). 
    This is how we recommend you manage your TLS support.
  EOF
}

######################
# Optional Variables #
######################

variable "cluster_id" {
  description = "ID of the ECS cluster this service should run in"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster this service should run in"
  default     = ""
}

variable "alb_access_logs" {
  description = "Map containing access logging configuration for the load balancer."
  type        = map(string)
  default     = {}
}

variable "incoming_cidr_ranges" {
  type        = list(string)
  description = <<EOF
  If you want to restrict the IP addresses that can talk to the
  internal sombra service, you can do so with this cidr block.

  Oftentimes, this will be the cidr block of the VPC containing the
  application you are calling the sombra api from.
  EOF
  default     = ["0.0.0.0/0"]
}

variable "transcend_backend_ips" {
  type        = list(string)
  default     = ["52.215.231.215/32", "63.34.48.255/32", "34.249.254.13/32", "54.75.178.77/32"]
  description = "The IP addresses of Transcend"
}

variable "use_local_kms" {
  default     = true
  description = "When true, local KMS will be used. When false, AWS will be used"
}

variable "jwt_ecdsa_key" {
  default     = ""
  description = <<EOF
  The JSON Web Token asymmetric key for signing Sombra payloads, using the Elliptic
  Curve Digital Signature Algorithm"
  EOF
}

variable "internal_key_hash" {
  default     = ""
  description = "This will override the generated internal key"
}

variable "transcend_backend_url" {
  default     = "https://api.transcend.io:443"
  description = "URL of Transcend's backend"
}

variable "transcend_certificate_common_name" {
  default     = "*.transcend.io"
  description = "Transcend's certificate Common NameTranscend's certificate Common Name"
}

variable "saml_config" {
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
  cert: the IDP's public signing certificate used to validate the signatures of the incoming SAML Responses. 
        The lines "BEGIN CERTIFICATE" and "END CERTIFICATE" should be stripped out and the certificate should be provided on a single line.
  audience: expected saml response Audience (if not provided, Audience won't be verified)
  acceptedClockSkewMs: Time in milliseconds of skew that is acceptable between client and server when
                       checking OnBefore and NotOnOrAfter assertion condition validity timestamps.
                       Setting to -1 will disable checking these conditions entirely.
  EOF
}

variable "oauth_config" {
  type = object({
    scopes                      = list(string)
    client_id                   = string
    secret_id                   = string
    get_token_body_redirect_uri = string
    get_token_url               = string
    get_core_id_url             = string
    get_core_id_path            = string
    get_profile_picture_url     = string
    get_profile_picture_path    = string
    get_email_url               = string
    get_email_path              = string
    email_is_verified_path      = string
    email_is_verified           = bool
  })
  default = {
    scopes                      = []
    client_id                   = ""
    secret_id                   = ""
    get_token_body_redirect_uri = ""
    get_token_url               = ""
    get_core_id_url             = ""
    get_core_id_path            = ""
    get_profile_picture_url     = ""
    get_profile_picture_path    = ""
    get_email_url               = ""
    get_email_path              = ""
    email_is_verified_path      = ""
    email_is_verified           = false
  }
  description = <<EOF
  Info about OAuth logins, used if OAuth is an enabled auth_method.

  The secret_id field is sensitive.
  EOF
}

variable "jwt_authentication_public_key" {
  default     = ""
  description = "Customer's data subject authentication via JWT public key"
}

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  default     = "eu-west-1"
}

variable "internal_port" {
  description = "The port the internal sombra should run on. This is the server that your internal services will have access to."
  default     = 443
}

variable "external_port" {
  description = "The port the external sombra should run on, this is the server that only Transcend's API talks to."
  default     = 5041
}

variable "log_level" {
  description = "The level at which logs should go to console: see https://github.com/pinojs/pino"
  default     = "warn"
}

variable "use_cloudwatch_logs" {
  type        = bool
  description = "If true, a cloudwatch group will be created and written to."
  default     = true
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable "log_configuration" {
  type = object({
    logDriver = string
    options   = map(string)
  })
  default = {
    logDriver = "awslogs"
    options   = {}
  }
  description = <<EOF
  Log configuration options to send to a custom log driver for the container.
  For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html

  This parameter is ignored if use_cloudwatch_logs is true, and a log group will be automatically
  written to.

  Use log_secrets to set extra options here that should be secret, such as API keys for third party loggers.
  EOF
}

variable "log_secrets" {
  type        = map(string)
  default     = {}
  description = "Used to add extra options to log_configuration.options that should be secret, such as third party API keys"
}

variable "extra_container_definitions" {
  type        = list(string)
  description = <<EOF
  Extra ECS container definitions to add to the task.

  This can be used to add sidecar containers such as AWS firelens, Datadog agent, etc.

  If you're using the fargate_container_definition module from this
  repo, then each value in the list can be the `json_map` output.
  EOF
  default     = []
}

variable "sombra_container_cpu" {
  default     = 512
  description = "How much CPU should be allocated to the sombra container?"
}

variable "sombra_container_memory" {
  default     = 2048
  description = "How much memory should be allocated to the sombra container?"
}

variable "cpu" {
  default     = 2048
  description = "How much CPU should be allocated to the entire ECS Task?"
}

variable "memory" {
  default     = 4096
  description = "How much memory should be allocated to the entire ECS Task?"
}

variable "extra_task_policy_arns" {
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

variable "use_private_load_balancer" {
  type        = bool
  default     = false
  description = <<EOF
  If true, the internal load balancer will not have publically accessible DNS.

  Use this if you plan to put this module into the same VPC as your backend,
  or if you want to set up VPC Peering from your backend to the VPC that holds
  the Sombra load balancers.
  EOF
}

variable "override_alb_name" {
  type        = string
  default     = null
  description = "If set as a string, this custom name will be used on the alb resources"
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle"
}

variable "extra_envs" {
  type        = map(string)
  description = <<EOF
  A map of custom environment variables to set on the Sombra container.

  The envs set here will overwrite any other envs on the container set in this module.

  Example: {
    SOME_ENV = "value"
    SOME_LOGGING_LEVEL = "info"
  }
  EOF
  default     = {}
}

variable "extra_secret_envs" {
  type        = map(string)
  description = <<EOF
  A map of custom, secretive environment variables to set on the Sombra container.

  The envs set here will overwrite any other envs on the container set in this module.

  Example: {
    SOME_SECRET_ENV = "some_cryptographically_signed_value"
  }
  EOF
  default     = {}
}

variable use_network_load_balancer {
  type        = bool
  description = <<EOF
  If true, the internal load balancer will use a Network Load Balancer instead of an Application Load Balancer.

  Use this if you plan to terminate SSL on the sombra itself, and not on the load balancer. This should always be
  used with `tls_config`.
  EOF
  default = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
  default     = {}
}


#####################
# Scaling Variables #
#####################

variable "desired_count" {
  type        = number
  description = "If not using Application Auto-scaling, the number of tasks to keep alive at all times"
  default     = null
}

variable "use_autoscaling" {
  type        = bool
  description = "Use Application Auto-scaling to scale service"
  default     = false
}

variable "min_desired_count" {
  type        = number
  description = "If using Application auto-scaling, minimum number of tasks to keep alive at all times"
  default     = null
}

variable "max_desired_count" {
  type        = number
  description = "If using Application auto-scaling, maximum number of tasks to keep alive at all times"
  default     = null
}

variable "scaling_target_value" {
  type        = number
  description = "If using Application auto-scaling, the target value to hit for the Auto-scaling policy"
  default     = null
}

variable "scaling_metric" {
  type        = string
  description = "If using Application auto-scaling, the pre-defined AWS metric to use for the Auto-scaling policy"
  default     = "ALBRequestCountPerTarget"
}

variable "health_check_protocol" {
  type        = string
  description = "HTTP/HTTPS protocol to use on the health check"
  default     = "HTTPS"
}

variable "roles_to_assume" {
  type        = list(string)
  description = "AWS IAM Roles that sombra can assume, used in AWS integrations"
  default     = []
}

