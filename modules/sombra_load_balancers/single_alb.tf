#################
# Load Balancer #
#################

locals {
  should_override_name = try(length(var.override_alb_name) > 0, false)
  alb_name             = local.should_override_name ? var.override_alb_name : "${var.project_id}-sombra-alb"
}

module "load_balancer" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.10.0"

  create_lb = !var.use_private_load_balancer

  # General Settings
  name                       = local.alb_name
  enable_deletion_protection = false
  access_logs                = var.alb_access_logs
  idle_timeout               = var.idle_timeout

  # VPC Settings
  subnets         = var.public_subnet_ids
  vpc_id          = var.vpc_id
  security_groups = [module.single_security_group.this_security_group_id]

  load_balancer_type = var.use_network_load_balancer ? "network" : "application"

  # Listeners for ALB
  https_listeners = var.use_network_load_balancer ? null : [
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
      ssl_policy         = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
      target_group_index = 1
    },
  ]

  # Listeners for NLB
  http_tcp_listeners = var.use_network_load_balancer ? [{
    port               = var.internal_port
    protocol           = "TCP"
    target_group_index = 0
  },{
    port               = var.external_port
    protocol           = "TCP"
    target_group_index = 1
  }] : null

  # Target groups
  target_groups = [
    # Internal group
    {
      name             = "${var.deploy_env}-${var.project_id}-internal"
      backend_protocol = var.health_check_protocol
      target_type      = "ip"
      backend_port     = var.internal_port
      health_check = {
        enabled  = true
        interval = 30
        port     = var.internal_port
        path     = "/health"
        protocol = var.health_check_protocol
      }
    },
    # External group
    {
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
    },
  ]

  tags = var.tags
}

module "single_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  create = !var.use_private_load_balancer

  name        = "${var.project_id}-sombra-alb"
  description = "Security group for sombra alb"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      protocol    = "tcp",
      from_port   = var.external_port,
      to_port     = var.external_port,
      cidr_blocks = join(",", var.transcend_backend_ips)
      description = "Allow communications from Transcend to External Service"
    },
    {
      protocol    = "tcp"
      from_port   = var.internal_port
      to_port     = var.internal_port
      cidr_blocks = join(",", var.incoming_cidr_ranges)
      description = "Allow communication to the internal service from your backend"
    }
  ]

  egress_with_cidr_blocks = [
    {
      protocol    = "tcp"
      from_port   = var.internal_port
      to_port     = var.internal_port
      cidr_blocks = join(",", var.private_subnets_cidr_blocks)
      description = "Allow talking to the internal sombra service"
    },
    {
      protocol    = "tcp"
      from_port   = var.external_port
      to_port     = var.external_port
      cidr_blocks = join(",", var.private_subnets_cidr_blocks)
      description = "Allow talking to the external sombra service"
    },
  ]

  tags = var.tags
}

##################################################
# Make a public DNS record for the load balancer #
##################################################

resource "aws_route53_record" "single_alb_alias" {
  count = var.use_private_load_balancer ? 0 : 1

  zone_id = var.zone_id
  name    = "${var.subdomain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = module.load_balancer.this_lb_dns_name
    zone_id                = module.load_balancer.this_lb_zone_id
    evaluate_target_health = false
  }
}
