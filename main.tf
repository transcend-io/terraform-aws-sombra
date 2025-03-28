############
# ECS Task #
############

module "container_definition" {
  source  = "transcend-io/fargate-container/aws"
  version = "1.10.0"

  name           = "${var.deploy_env}-${var.project_id}-container"
  image          = var.ecr_image
  containerPorts = [var.internal_port]
  ssm_prefix     = var.project_id

  portNames = tomap({
    tostring(var.internal_port) = "internalSombra",
  })

  use_cloudwatch_logs = var.use_cloudwatch_logs
  log_configuration   = var.log_configuration
  log_secrets         = var.log_secrets

  cpu               = var.sombra_container_cpu
  memory            = var.sombra_container_memory
  memoryReservation = var.sombra_container_memory

  environment = merge({
    # General Settings
    LLM_CLASSIFIER_URL = var.deploy_llm ? "http://llm-classifier:${var.llm_classifier_port}" : null

    # JWT Auth Settings
    JWT_AUTHENTICATION_PUBLIC_KEY = var.jwt_authentication_public_key

    # AWS KMS
    AWS_KMS_KEY_ARN = var.use_local_kms ? "" : aws_kms_key.key.0.arn
    KMS_PROVIDER    = var.use_local_kms ? "local" : "AWS"
    AWS_REGION      = var.aws_region

    # Override internal key
    INTERNAL_KEY_HASH = var.internal_key_hash

    NODE_ENV      = "production"
    TRANSCEND_URL = var.transcend_backend_url
    LOG_LEVEL     = var.log_level

    # Global Settings
    ORGANIZATION_URI                    = var.organization_uri
    SOMBRA_ID                           = var.sombra_id
    DATA_SUBJECT_AUTHENTICATION_METHODS = join(",", var.data_subject_auth_methods)
    EMPLOYEE_AUTHENTICATION_METHODS     = join(",", var.employee_auth_methods)
    INTERNAL_PORT                       = var.internal_port

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
    OAUTH_GET_TOKEN_BODY_REDIRECT_URI = var.oauth_config.get_token_body_redirect_uri
    OAUTH_GET_CORE_ID_URL             = var.oauth_config.get_core_id_url
    OAUTH_GET_CORE_ID_PATH            = var.oauth_config.get_core_id_path
    OAUTH_GET_PROFILE_PICTURE_URL     = var.oauth_config.get_profile_picture_url
    OAUTH_GET_PROFILE_PICTURE_PATH    = var.oauth_config.get_profile_picture_path
    OAUTH_GET_EMAIL_URL               = var.oauth_config.get_email_url
    OAUTH_GET_EMAIL_PATH              = var.oauth_config.get_email_path
    OAUTH_EMAIL_IS_VERIFIED_PATH      = var.oauth_config.email_is_verified_path
    OAUTH_EMAIL_IS_VERIFIED           = var.oauth_config.email_is_verified
  }, var.extra_envs)

  secret_environment = merge({
    for key, val in {
      OAUTH_CLIENT_SECRET           = var.oauth_config.secret_id
      JWT_ECDSA_KEY                 = var.jwt_ecdsa_key
      SOMBRA_REVERSE_TUNNEL_API_KEY = var.sombra_reverse_tunnel_api_key
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
  source  = "transcend-io/fargate-service/aws"
  version = "0.9.4"

  name         = "${var.deploy_env}-${var.project_id}-sombra-service"
  cpu          = var.cpu
  memory       = var.memory
  cluster_id   = local.cluster_id
  cluster_name = local.cluster_name

  service_connect_namespace = local.cluster_namespace

  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
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
    var.extra_task_policy_arns,
    length(var.roles_to_assume) > 0 ? [aws_iam_policy.aws_policy[0].arn] : [],
  )
  additional_task_policy_arns_count = 2 + length(var.extra_task_policy_arns) + (length(var.roles_to_assume) > 0 ? 1 : 0)

  # Scaling configuration.
  desired_count                  = var.desired_count
  min_desired_count              = var.min_desired_count
  max_desired_count              = var.max_desired_count

  deploy_env = var.deploy_env
  aws_region = var.aws_region
  tags       = var.tags
}

###############
# ECS Cluster #
###############

resource "aws_service_discovery_http_namespace" "sombra_namespace" {
  count = var.cluster_id == "" ? 1 : 0
  name        = "${var.deploy_env}-${var.project_id}-transcend"
  description = "Service Discovery namespace for Transcend services such as Sombra and the LLM Classifier"
}

resource "aws_ecs_cluster" "cluster" {
  count = var.cluster_id == "" ? 1 : 0
  name  = "${var.deploy_env}-${var.project_id}-sombra-cluster"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.sombra_namespace[0].arn
  }

  tags  = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "capacity_with_fargate_and_gpu" {
  count = var.cluster_id == "" && var.deploy_llm ? 1 : 0
  cluster_name = aws_ecs_cluster.cluster[0].name

  capacity_providers = ["FARGATE", aws_ecs_capacity_provider.llm_classifier_capacity_provider[0].name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_capacity_provider" "llm_classifier_capacity_provider" {
  count = var.cluster_id == "" && var.deploy_llm ? 1 : 0
  name = "${var.deploy_env}-${var.project_id}-llm-classifier-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.llm_classifier_asg[0].arn
    managed_termination_protection = "DISABLED"
  }
}

resource "aws_autoscaling_group" "llm_classifier_asg" {
  count = var.cluster_id == "" && var.deploy_llm ? 1 : 0
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = var.private_subnet_ids
  launch_configuration = aws_launch_configuration.llm_classifier_lc[0].id
  tag {
    key                 = "Name"
    value               = "${var.deploy_env}-${var.project_id}-llm-classifier-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended"
}

resource "aws_launch_configuration" "llm_classifier_lc" {
  count = var.cluster_id == "" && var.deploy_llm ? 1 : 0
  name_prefix          = "${var.deploy_env}-${var.project_id}-llm-classifier"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value).image_id
  instance_type = var.llm_classifier_instance_type
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups = [aws_security_group.llm_classifier_instances_sg.id]

  root_block_device {
    volume_size = 100
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${local.cluster_name}" >> /etc/ecs/ecs.config
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "llm_classifier_instances_sg" {
  name        = "${var.deploy_env}-${var.project_id}-llm-classifier-instances-sg"
  description = "Security group for LLM Classifier ECS instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.deploy_env}-${var.project_id}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name   = "${var.deploy_env}-${var.project_id}-ecs-instance-role-policy"
  role   = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.deploy_env}-${var.project_id}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

locals {
  cluster_id   = var.cluster_id == "" ? aws_ecs_cluster.cluster[0].id : var.cluster_id
  cluster_name = var.cluster_name == "" ? aws_ecs_cluster.cluster[0].name : var.cluster_name
  cluster_namespace = var.cluster_namespace == "" ? aws_service_discovery_http_namespace.sombra_namespace[0].name : var.cluster_namespace
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

  statement {
    sid     = "AllowGeneratingRandom"
    effect  = "Allow"
    actions = ["kms:GenerateRandom"]
    # This has to be a `*` since `kms:GenerateRandom` does not allow for specific resources.
    resources = ["*"]
  }
}

resource "aws_iam_policy" "kms_policy" {
  name        = "${var.deploy_env}-${var.project_id}-sombra-kms-policy"
  description = "Allows Sombra instances to get the KMS key"
  policy      = data.aws_iam_policy_document.kms_policy_doc.json
}

############################
# AWS Integration Policies #
############################

data "aws_iam_policy_document" "aws_policy_doc" {
  statement {
    sid       = "AllowAwsIntegrationAccess"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = var.roles_to_assume
  }
}

resource "aws_iam_policy" "aws_policy" {
  count       = length(var.roles_to_assume) > 0 ? 1 : 0
  name        = "${var.deploy_env}-${var.project_id}-sombra-aws-policy"
  description = "Allows Sombra instances to assume AWS IAM Roles"
  policy      = data.aws_iam_policy_document.aws_policy_doc.json
}

##################
# LLM Classifier #
##################

resource "aws_cloudwatch_log_group" "llm_logs" {
  count = var.use_cloudwatch_logs ? 1 : 0
  name  = "${var.deploy_env}-${var.project_id}-llm-classifier-log-group"
  tags  = var.tags
}

resource "aws_ecs_task_definition" "llm_classifier_task" {
  count                    = var.deploy_llm ? 1 : 0
  family                   = "${var.deploy_env}-${var.project_id}-llm-classifier"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "2048"
  memory                   = "8192"
  execution_role_arn       = module.service.role_arn
  task_role_arn            = module.service.role_arn

  container_definitions = jsonencode([
    {
      name      = "sombra-llm-classifier"
      image     = var.llm_classifier_ecr_image
      essential = true
      memory    = 8192
      cpu       = 2048
      "portMappings": [
        {
          containerPort = var.llm_classifier_port
          hostPort = var.llm_classifier_port
          name = "llm-classifier"
          protocol = "tcp"
        }
      ],
      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]
      environment = [
        { name = "LLM_SERVER_PORT", value = tostring(var.llm_classifier_port) },
        { name = "LLM_SERVER_CONCURRENCY", value = "2" },
        { name = "LLM_SERVER_TIMEOUT", value = "120" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.llm_logs[0].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "llm_classifier" {
  count           = var.deploy_llm ? 1 : 0
  name            = "${var.deploy_env}-${var.project_id}-llm-classifier"
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.llm_classifier_task[0].arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.llm_classifier_sg[0].id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = local.cluster_namespace
    service {
      discovery_name = "llm-classifier"
      port_name      = "llm-classifier"
      client_alias {
        dns_name = "llm-classifier"
        port     = var.llm_classifier_port
      }
    }
  }
}

resource "aws_security_group" "llm_classifier_sg" {
  count       = var.deploy_llm ? 1 : 0
  name        = "${var.deploy_env}-${var.project_id}-llm-classifier-sg"
  description = "Security group for Sombra LLM Classifier ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.llm_classifier_port
    to_port     = var.llm_classifier_port
    protocol    = "tcp"
    security_groups = [module.service.service_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}