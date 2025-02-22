######################
# Required Variables #
######################

variable "transcend_backend_url" {
  description = "URL of Transcend's backend. This changes by region, and will often be either https://api.transcend.io or https://api.us.transcend.io"
}

variable "sombra_reverse_tunnel_api_key" {
  description = "The API key for the Sombra. Given to you when you first create the sombra at https://app.transcend.io/infrastructure/sombra/sombras"
}

variable "organization_uri" {
  description = "The unique URI for you organization from Transcend."
}

variable "sombra_id" {
  description = "The unique ID of the sombra"
}

variable "vpc_id" {
  description = "The ID of the VPC to put this application into"
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

######################
# Optional Variables #
######################

variable "ecr_image" {
  description = "Url of the ECR repo, including the tag, for the Sombra image"
  default     = "829095311197.dkr.ecr.eu-west-1.amazonaws.com/sombra:prod"
}

variable "deploy_llm" {
  description = "If true, the LLM Classifier will be deployed. Note that this has considerable cost implications"
  default     = false
}

variable "project_id" {
  description = "A name to use in resources, such as the name of your company."
  default     = "sombra"
}

variable "llm_classifier_ecr_image" {
  description = "Url of the ECR repo, including the tag, for the LLM Classifier"
  default     = "829095311197.dkr.ecr.eu-west-1.amazonaws.com/llm-classifier:prod"
}

variable "llm_classifier_instance_type" {
  description = "The instance type to use for the LLM Classifier, which requires a GPU"
  default     = "g5.2xlarge"
}

variable "data_subject_auth_methods" {
  type        = list(string)
  description = "Supported data subject authentication methods"
  default     = ["transcend", "session"]
}

variable "deploy_env" {
  description = "The environment to deploy to, usually dev, staging, or prod"
  default     = "prod"
}

variable "employee_auth_methods" {
  type        = list(string)
  description = "Supported customer employee authentication methods"
  default     = ["transcend", "session"]
}

variable "cluster_id" {
  description = "ID of the ECS cluster this service should run in"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster this service should run in"
  default     = ""
}

variable "cluster_namespace" {
  type        = string
  description = "The service discovery namespace of the ECS cluster"
  default     = ""
}

variable "use_local_kms" {
  default     = true
  description = "When true, local KMS will be used. When false, AWS will be used"
}

variable "jwt_ecdsa_key" {
  default     = ""
  description = <<EOF
  The JSON Web Token asymmetric key for signing Sombra payloads, using the Elliptic
  Curve Digital Signature Algorithm.
  Generated via `openssl ecparam -genkey -name secp384r1 -noout | (base64 --wrap=0 2>/dev/null || base64 -b 0)`
  EOF
}

variable "internal_key_hash" {
  default     = ""
  description = "This will override the generated internal key"
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

variable "llm_classifier_port" {
  description = "The port the LLM Classifier should run on, if enabled"
  default     = 6081
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

variable "desired_count" {
  type        = number
  description = "If not using Application Auto-scaling, the number of tasks to keep alive at all times"
  default     = null
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

variable "roles_to_assume" {
  type        = list(string)
  description = "AWS IAM Roles that sombra can assume, used in AWS integrations"
  default     = []
}

variable "internal_port" {
  description = "The port the internal sombra should run on. This is the server that your internal services will have access to."
  default     = 443
}

variable "sombra_reverse_tunnel_use_https" {
  description = "If true, the reverse tunnel will use HTTPS. If false, it will use HTTP"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
  default     = {}
}