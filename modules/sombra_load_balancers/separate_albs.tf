###################################
# Internal, Private Load Balancer #
###################################

module internal_load_balancer {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.10.0"

  create_lb = var.use_private_load_balancer || var.use_network_load_balancer

  # General Settings
  name                       = "${var.project_id}-sombra-internal"
  enable_deletion_protection = false
  access_logs                = var.alb_access_logs
  idle_timeout               = var.idle_timeout

  # VPC Settings
  subnets         = var.use_private_load_balancer ? var.private_subnet_ids : var.public_subnet_ids
  vpc_id          = var.vpc_id
  security_groups = var.use_network_load_balancer ? [] : [module.internal_security_group.this_security_group_id]

  # Make this only internal to the VPC, if specified
  internal        = var.use_private_load_balancer
  ip_address_type = "ipv4"

  load_balancer_type = var.use_network_load_balancer ? "network" : "application"

  # Listeners if ALB
  https_listeners = var.use_network_load_balancer ? [] : [{
    certificate_arn = var.certificate_arn
    port            = var.internal_port
    ssl_policy      = var.ssl_policy
  }]

  # Listeners if NLB
  http_tcp_listeners = var.use_network_load_balancer ? [{
    port               = var.internal_port
    protocol           = "TCP"
    target_group_index = 0
  }] : []

  # Target groups
  target_groups = [{
    name             = "${var.deploy_env}-${var.project_id}-internal"
    backend_protocol = var.use_network_load_balancer ? "TCP" : var.health_check_protocol
    target_type      = "ip"
    backend_port     = var.internal_port
    health_check = {
      enabled  = true
      interval = 30
      port     = var.internal_port
      path     = "/health"
      protocol = var.health_check_protocol
    }
  }]

  tags = var.tags
}

module "internal_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  create = var.use_private_load_balancer && !var.use_network_load_balancer

  name        = "${var.project_id}-internal-alb"
  description = "Security group for the internal, private sombra alb"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [{
    protocol    = "tcp"
    from_port   = var.internal_port
    to_port     = var.internal_port
    cidr_blocks = join(",", var.incoming_cidr_ranges)
    description = "Allow private communications to internal load balancer"
  }]

  egress_with_cidr_blocks = [{
    protocol    = "tcp"
    from_port   = var.internal_port
    to_port     = var.internal_port
    cidr_blocks = join(",", var.private_subnets_cidr_blocks)
    description = "Allow the ALB to talk to the internal service"
  }]

  tags = var.tags
}

#############################################
# Make a private zone for the load balancer #
#############################################

resource "aws_route53_zone" "private" {
  count = var.use_private_load_balancer ? 1 : 0

  name = var.root_domain
  vpc { vpc_id = var.vpc_id }
  lifecycle { ignore_changes = [vpc] }
}

resource "aws_route53_record" "alb_alias" {
  count = var.use_private_load_balancer || var.use_network_load_balancer ? 1 : 0

  zone_id = var.use_private_load_balancer ? aws_route53_zone.private[0].zone_id : var.zone_id
  name    = "${var.subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = module.internal_load_balancer.this_lb_dns_name
    zone_id                = module.internal_load_balancer.this_lb_zone_id
    evaluate_target_health = false
  }
}

############################################
# External, Transcend Facing Load Balancer #
############################################

module external_load_balancer {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.10.0"

  create_lb = var.use_private_load_balancer || var.use_network_load_balancer

  # General Settings
  name                       = "${var.project_id}-sombra-external"
  enable_deletion_protection = false
  access_logs                = var.alb_access_logs

  # VPC Settings
  subnets         = var.public_subnet_ids
  vpc_id          = var.vpc_id
  security_groups = [module.external_security_group.this_security_group_id]

  # Listeners
  https_listeners = [{
    certificate_arn = var.certificate_arn
    port            = var.external_port
    ssl_policy      = var.ssl_policy
  }]

  # Target groups
  target_groups = [{
    name             = "${var.deploy_env}-${var.project_id}-external"
    backend_protocol = var.health_check_protocol
    target_type      = "ip"
    backend_port     = var.external_port
    health_check = {
      enabled  = true
      interval = 30
      port     = var.external_port
      path     = "/health"
      protocol = var.health_check_protocol
    }
  }]

  tags = var.tags
}

module "external_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  create = var.use_private_load_balancer || var.use_network_load_balancer

  name        = "${var.project_id}-external-alb"
  description = "Security group for the external, public sombra alb"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [{
    protocol    = "tcp"
    from_port   = var.external_port
    to_port     = var.external_port
    cidr_blocks = join(",", var.transcend_backend_ips)
    description = "Allow communications to external ALB from Transcend IPs over public DNS"
  }]

  egress_with_cidr_blocks = [{
    protocol    = "tcp"
    from_port   = var.external_port
    to_port     = var.external_port
    cidr_blocks = join(",", var.private_subnets_cidr_blocks)
    description = "Allow the ALB to talk to the external service"
  }]

  tags = var.tags
}

###########################################################
# Make a public DNS record for the external load balancer #
###########################################################

resource "aws_route53_record" "external_alb_alias" {
  count = var.use_private_load_balancer || var.use_network_load_balancer ? 1 : 0

  zone_id = var.zone_id
  name    = var.use_private_load_balancer ? "${var.subdomain}.${var.root_domain}" : "external-${var.subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = module.external_load_balancer.this_lb_dns_name
    zone_id                = module.external_load_balancer.this_lb_zone_id
    evaluate_target_health = false
  }
}
