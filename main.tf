#################
# Load Balancer #
#################

module "load_balancer" {
  source = "./modules/sombra_load_balancers"

  # General Settings
  override_alb_name = var.override_alb_name
  deploy_env        = var.deploy_env
  project_id        = var.project_id
  alb_access_logs   = var.alb_access_logs
  idle_timeout      = var.idle_timeout

  # Ports and Firewall settings
  internal_port         = var.internal_port
  external_port         = var.external_port
  transcend_backend_ips = var.transcend_backend_ips
  incoming_cidr_ranges  = var.incoming_cidr_ranges

  # VPC settings
  vpc_id                      = var.vpc_id
  public_subnet_ids           = var.public_subnet_ids
  private_subnet_ids          = var.private_subnet_ids
  private_subnets_cidr_blocks = var.private_subnets_cidr_blocks

  # DNS Settings
  subdomain                 = var.subdomain
  root_domain               = var.root_domain
  zone_id                   = var.zone_id
  certificate_arn           = var.certificate_arn
  use_private_load_balancer = var.use_private_load_balancer

  tags = var.tags
}

############
# ECS Task #
############

module "container_definition" {
  source  = "transcend-io/fargate-container/aws"
  version = "1.7.1"

  name           = "${var.deploy_env}-${var.project_id}-container"
  image          = var.ecr_image
  containerPorts = [var.internal_port, var.external_port]
  ssm_prefix     = var.project_id

  use_cloudwatch_logs = var.use_cloudwatch_logs
  log_configuration   = var.log_configuration
  log_secrets         = var.log_secrets

  cpu               = var.sombra_container_cpu
  memory            = var.sombra_container_memory
  memoryReservation = var.sombra_container_memory

  environment = merge({
    # General Settings
    EXTERNAL_PORT_HTTPS = var.external_port
    INTERNAL_PORT_HTTPS = var.internal_port
    USE_TLS_AUTH        = false

    # JWT
    JWT_AUTHENTICATION_PUBLIC_KEY = var.jwt_authentication_public_key

    # AWS KMS
    AWS_KMS_KEY_ARN = var.use_local_kms ? "" : aws_kms_key.key.0.arn
    KMS_PROVIDER    = var.use_local_kms ? "local" : "AWS"
    AWS_REGION      = var.aws_region

    # Override internal key
    INTERNAL_KEY_HASH = var.internal_key_hash

    NODE_ENV      = "production"
    TRANSCEND_URL = var.transcend_backend_url
    TRANSCEND_CN  = var.transcend_certificate_common_name
    LOG_LEVEL     = var.log_level

    # Global Settings
    ORGANIZATION_URI                    = var.organization_uri
    DATA_SUBJECT_AUTHENTICATION_METHODS = join(",", var.data_subject_auth_methods)
    EMPLOYEE_AUTHENTICATION_METHODS     = join(",", var.employee_auth_methods)

    # Employee Single Sign On
    SAML_ENTRYPOINT             = var.saml_config.entrypoint
    SAML_ISSUER                 = var.saml_config.issuer
    SAML_CERT                   = var.saml_config.cert
    SAML_AUDIENCE               = var.saml_config.audience
    SAML_ACCEPT_CLOCK_SKEWED_MS = var.saml_config.accepted_clock_skew_ms

    # Data Subject OAuth
    OAUTH_SCOPES                      = join(",", var.oauth_config.scopes)
    OAUTH_CLIENT_ID                   = var.oauth_config.client_id
    OAUTH_GET_TOKEN_URL               = var.oauth_config.get_token_url
    OAUTH_GET_CORE_ID_URL             = var.oauth_config.get_core_id_url
    OAUTH_GET_CORE_ID_PATH            = var.oauth_config.get_core_id_path
    OAUTH_GET_PROFILE_URL             = var.oauth_config.get_profile_url
    OAUTH_GET_TOKEN_BODY_REDIRECT_URI = var.oauth_config.get_token_body_redirect_uri
    OAUTH_GET_PROFILE_PATH            = var.oauth_config.get_profile_path
    OAUTH_GET_EMAIL_PATH              = var.oauth_config.get_email_path
    OAUTH_PROFILE_PICTURE_PATH        = var.oauth_config.profile_picture_path
    OAUTH_EMAIL_IS_VERIFIED_PATH      = var.oauth_config.email_is_verified_path
    OAUTH_EMAIL_IS_VERIFIED           = var.oauth_config.email_is_verified
  }, var.extra_envs)

  secret_environment = merge({
    for key, val in {
      OAUTH_CLIENT_SECRET       = var.oauth_config.secret_id
      JWT_ECDSA_KEY             = var.jwt_ecdsa_key
      SOMBRA_TLS_KEY            = var.tls_config.key
      SOMBRA_TLS_KEY_PASSPHRASE = var.tls_config.passphrase
      SOMBRA_TLS_CERT           = var.tls_config.cert
    } :
    key => val
    if try(length(val) > 0, false)
  }, var.extra_secret_envs)

  deploy_env = var.deploy_env
  aws_region = var.aws_region
  tags       = var.tags
}

###############
# ECS Service #
###############

module "service" {
  # FIXME
#  source  = "transcend-io/fargate-service/aws"
#  version = "0.6.0"
  source = "git::https://github.com/transcend-io/fargate-aws-fargate-service.git?ref=dipack/fix-ignore-changes"

  name                   = "${var.deploy_env}-${var.project_id}-sombra-service"
  cpu                    = var.cpu
  memory                 = var.memory
  cluster_id             = local.cluster_id
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  alb_security_group_ids = module.load_balancer.security_group_ids
  container_definitions = format(
    "[%s]",
    join(",", distinct(concat(
      [module.container_definition.json_map],
      var.extra_container_definitions
    )))
  )

  additional_task_policy_arns = concat(
    module.container_definition.secrets_policy_arns,
    [aws_iam_policy.kms_policy.arn],
    var.extra_task_policy_arns
  )
  additional_task_policy_arns_count = 2 + length(var.extra_task_policy_arns)

  load_balancers = [
    # Internal target group manager
    {
      target_group_arn = module.load_balancer.internal_target_group_arn
      container_name   = module.container_definition.container_name
      container_port   = var.internal_port
    },
    # External target group manager
    {
      target_group_arn = module.load_balancer.external_target_group_arn
      container_name   = module.container_definition.container_name
      container_port   = var.external_port
    }
  ]

  # Scaling configuration.
  desired_count        = var.desired_count
  use_autoscaling      = var.use_autoscaling
  min_desired_count    = var.min_desired_count
  max_desired_count    = var.max_desired_count
  scaling_target_value = var.scaling_target_value
  scaling_metric       = var.scaling_metric

  deploy_env = var.deploy_env
  aws_region = var.aws_region
  tags       = var.tags
}

###############
# ECS Cluster #
###############

resource "aws_ecs_cluster" "cluster" {
  count = var.cluster_id == "" ? 1 : 0
  name  = "${var.deploy_env}-${var.project_id}-sombra-cluster"
  tags  = var.tags
}

locals {
  cluster_id = var.cluster_id == "" ? aws_ecs_cluster.cluster[0].id : var.cluster_id
}

##############
# KMS Policy #
##############

resource "aws_kms_key" "key" {
  count       = var.use_local_kms ? 0 : 1
  description = "Encryption key for ${var.deploy_env} ${var.project_id} Sombra"
  tags        = var.tags
}

data "aws_iam_policy_document" "kms_policy_doc" {
  statement {
    sid    = "AllowReadingKms"
    effect = "Allow"
    # TODO: Make the actions tighter.
    actions   = ["kms:*"]
    resources = var.use_local_kms ? ["*"] : [aws_kms_key.key.0.arn]
  }
}

resource "aws_iam_policy" "kms_policy" {
  name        = "${var.deploy_env}-${var.project_id}-sombra-kms-policy"
  description = "Allows Sombra instances to get the KMS key"
  policy      = data.aws_iam_policy_document.kms_policy_doc.json
}
