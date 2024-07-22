variable use_private_load_balancer {
  type        = bool
  description = <<EOF
  If true, the internal load balancer will not have publically accessible DNS.

  Use this if you plan to put this module into the same VPC as your backend,
  or if you want to set up VPC Peering from your backend to the VPC that holds
  the Sombra load balancers.
  EOF
}

variable use_network_load_balancer {
  type        = bool
  description = <<EOF
  If true, the internal load balancer will use a Network Load Balancer instead of an Application Load Balancer.

  Use this if you plan to terminate SSL on the sombra itself, and not on the load balancer. This should always be
  used with `tls_config` on the root module.
  EOF
  default = false
}

variable deploy_env {
  description = "The environment to deploy to, usually dev, staging, or prod"
}

variable project_id {
  description = "A name to use in resources, such as the name of your company."
}

variable "alb_access_logs" {
  description = "Map containing access logging configuration for the load balancer."
  type        = map(string)
  default     = {}
}

variable certificate_arn {
  description = "Arn of the ACM cert that exists on the ALB"
}

variable internal_port {
  description = "The port the internal sombra should run on. This is the server that your internal services will have access to."
  default     = 443
}

variable external_port {
  description = "The port the external sombra should run on, this is the server that only Transcend's API talks to."
  default     = 5041
}

variable transcend_backend_ips {
  type        = list(string)
  default     = ["52.215.231.215/32", "63.34.48.255/32", "34.249.254.13/32", "54.75.178.77/32"]
  description = "The IP addresses of Transcend"
}

variable incoming_cidr_ranges {
  type        = list(string)
  description = <<EOF
  If you want to restrict the IP addresses that can talk to the
  internal sombra service, you can do so with this cidr block.

  Oftentimes, this will be the cidr block of the VPC containing the
  application you are calling the sombra api from.
  EOF
  default     = ["0.0.0.0/0"]
}

variable vpc_id {
  description = "The ID of the VPC to put the load balancer(s) into"
}

variable public_subnet_ids {
  type        = list(string)
  description = "The subnets the external ALB can be placed into"
}

variable private_subnet_ids {
  type        = list(string)
  description = "The subnets the ECS tasks can be placed into, as well as the internal load balancer if desired"
}

variable private_subnets_cidr_blocks {
  type        = list(string)
  description = "CIDR blocks that an ECS task could be in"
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

variable zone_id {
  description = "The ID of the Route53 hosted zone where the public sombra subdomain will be created"
}

variable override_alb_name {
  type        = string
  default     = null
  description = "If set as a string, this custom name will be used on the alb resources"
}

variable "idle_timeout" {
  type = number
  default = 60
  description = "The time in seconds that the connection is allowed to be idle"
}

variable "health_check_protocol" {
  type        = string
  description = "HTTP/HTTPS protocol to use on the health check"
  default     = "HTTPS"
}

variable "ssl_policy" {
  type        = string
  description = "The Security Policy to use for SSL on the load balancers"
  default     = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

variable tags {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
  default     = {}
}
