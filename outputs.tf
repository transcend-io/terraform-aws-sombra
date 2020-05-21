output internal_url {
  value       = "https://${var.subdomain}.${var.root_domain}:${var.internal_port}"
  description = "Url of the internal sombra service. Depending on settings, it may only be accessible inside the VPC"
}

output external_url {
  value       = "https://${var.subdomain}.${var.root_domain}:${var.external_port}"
  description = "Url of the external sombra service. It is publically accessible"
}

output private_zone_id {
  value       = module.load_balancer.private_zone_id
  description = "The hosted zone id of the private zone for the internal load balancer, if a private zone exists"
}

output internal_listener_arn {
  value       = module.load_balancer.internal_listener_arn
  description = "ARN of the internal sombra load balancer listener"
}

output external_listener_arn {
  value       = module.load_balancer.external_listener_arn
  description = "ARN of the external sombra load balancer listener"
}