output internal_target_group_arn {
  value       = var.use_private_load_balancer ? module.internal_load_balancer.target_group_arns[0] : module.load_balancer.target_group_arns[0]
  description = "ARN of the internal sombra load balancer target group"
}

output external_target_group_arn {
  value       = var.use_private_load_balancer ? module.external_load_balancer.target_group_arns[0] : module.load_balancer.target_group_arns[1]
  description = "ARN of the external sombra load balancer target group"
}

output security_group_ids {
  value       = var.use_private_load_balancer ? [module.internal_security_group.this_security_group_id, module.external_security_group.this_security_group_id] : [module.single_security_group.this_security_group_id]
  description = "The ids of all security groups set on the ALB. We require that the tasks can only talk to the ALB"
}

output private_zone_id {
  value       = var.use_private_load_balancer ? aws_route53_zone.private[0].zone_id : ""
  description = "The hosted zone id of the private zone for the internal load balancer, if a private zone exists"
}

output internal_listener_arn {
  value       = var.use_network_load_balancer ? var.load_balancer.http_tcp_listener_arns[0] : var.use_private_load_balancer ? module.internal_load_balancer.https_listener_arns[0] : module.load_balancer.https_listener_arns[0]
  description = "ARN of the internal sombra load balancer listener"
}

output external_listener_arn {
  value       = var.use_network_load_balancer ? var.load_balancer.http_tcp_listener_arns[0] : var.use_private_load_balancer ? module.external_load_balancer.https_listener_arns[0] : module.load_balancer.https_listener_arns[1]
  description = "ARN of the external sombra load balancer listener"
}

output arn_suffix {
  value       = var.use_private_load_balancer ? "" : module.load_balancer.this_lb_arn_suffix
  description = "Amazon Resource Name suffix for the load balancer. Only present in single alb configurations"
}