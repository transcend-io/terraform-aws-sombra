#################
# Load Balancer #
#################

module load_balancer {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  # General Settings
  name                       = "${var.deploy_env}-sombra-${var.project_id}-alb"
  enable_deletion_protection = false
  access_logs                = var.alb_access_logs

  # VPC Settings
  subnets         = var.public_subnet_ids
  vpc_id          = var.vpc_id
  security_groups = [aws_security_group.alb.id]

  # Listeners
  https_listeners = [
    # Internal Listener
    {
      certificate_arn    = var.certificate_arn
      port               = var.internal_port
      ssl_policy         = "ELBSecurityPolicy-2016-08"
      target_group_index = 0
    },
    # External Listener
    {
      certificate_arn    = var.certificate_arn
      port               = var.external_port
      ssl_policy         = "ELBSecurityPolicy-FS-2018-06"
      target_group_index = 1
    },
  ]

  # Target groups
  target_groups = [
    # Internal group
    {
      name              = "${var.deploy_env}-${var.project_id}-internal"
      health_check_path = "/health"
      backend_protocol  = "HTTPS"
      target_type       = "ip"
      backend_port      = var.internal_port
      health_check_port = var.internal_port
    },
    # External group
    {
      name              = "${var.deploy_env}-${var.project_id}-external"
      health_check_path = "/health"
      backend_protocol  = "HTTPS"
      target_type       = "ip"
      backend_port      = var.external_port
      health_check_port = var.external_port
    },
  ]
}

resource "aws_security_group" "alb" {
  name        = "${var.deploy_env}-${var.project_id}-sombra-alb-security-group"
  description = "Security group for sombra alb"
  vpc_id      = var.vpc_id

  # Allow external port
  ingress {
    protocol    = "tcp"
    from_port   = var.external_port
    to_port     = var.external_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow internal port from the calling companies IP range
  ingress {
    protocol    = "tcp"
    from_port   = var.internal_port
    to_port     = var.internal_port
    cidr_blocks = [var.incoming_cidr_range]
  }

  egress {
    protocol    = "tcp"
    from_port   = var.internal_port
    to_port     = var.internal_port
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  egress {
    protocol    = "tcp"
    from_port   = var.external_port
    to_port     = var.external_port
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  timeouts {
    create = "45m"
    delete = "45m"
  }
}

############
# ECS Task #
############

module container_definition {
  source = "./modules/fargate_container_definition"

  name           = "${var.deploy_env}-${var.project_id}-container"
  image          = var.ecr_image
  containerPorts = [var.internal_port, var.external_port]
  ssm_prefix     = var.project_id

  use_cloudwatch_logs = var.use_cloudwatch_logs
  log_configuration   = var.log_configuration
  log_secrets         = var.log_secrets

  environment = {
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

    # Cycle
    HMAC_NONCE_KEY_CYCLE      = var.hmac_nonce_key_cycle
    KEY_ENCRYPTION_BASE_CYCLE = var.key_encryption_base_cycle

    NODE_ENV                    = "production"
    TRANSCEND_URL               = var.transcend_backend_url
    TRANSCEND_CN                = var.transcend_certificate_common_name
    LOG_LEVEL                   = var.log_level
    ENCRYPTED_SAAS_HTTP_METHODS = join(",", var.encrypted_saas_http_methods)

    # Global Settings
    ORGANIZATION_URI                    = var.subdomain
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
  }

  secret_environment = {
    for key, val in {
      OAUTH_CLIENT_SECRET       = var.oauth_config.secret_id
      JWT_ECDSA_KEY             = var.jwt_ecdsa_key
      SOMBRA_TLS_KEY            = var.tls_config.key
      SOMBRA_TLS_KEY_PASSPHRASE = var.tls_config.passphrase
      SOMBRA_TLS_CERT           = var.tls_config.cert
    } :
    key => val
    if length(val) > 0
  }

  deploy_env = var.deploy_env
  aws_region = var.aws_region
  tags       = var.tags
}

###############
# ECS Service #
###############

module service {
  source = "./modules/fargate_service"

  name                   = "${var.deploy_env}-${var.project_id}-sombra-service"
  desired_count          = var.desired_count
  cpu                    = var.cpu
  memory                 = var.memory
  cluster_id             = local.cluster_id
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  alb_security_group_ids = [aws_security_group.alb.id]
  container_definitions = format(
    "[%s]",
    join(",", setunion(
      [module.container_definition.json_map],
      var.extra_container_definitions
    ))
  )

  additional_task_policy_arns = concat([
    module.container_definition.secrets_policy_arn,
    aws_iam_policy.kms_policy.arn,
  ], var.extra_task_policy_arns)
  additional_task_policy_arns_count = 2 + length(var.extra_task_policy_arns)

  load_balancers = [
    # Internal target group manager
    {
      target_group_arn = module.load_balancer.target_group_arns[0]
      container_name   = module.container_definition.container_name
      container_port   = var.internal_port
    },
    # External target group manager
    {
      target_group_arn = module.load_balancer.target_group_arns[1]
      container_name   = module.container_definition.container_name
      container_port   = var.external_port
    }
  ]

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

#######
# DNS #
#######

resource "aws_route53_record" "alb_alias" {
  zone_id = var.zone_id
  name    = "${var.subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = module.load_balancer.this_lb_dns_name
    zone_id                = module.load_balancer.this_lb_id
    evaluate_target_health = false
  }
}
