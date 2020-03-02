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
  value = var.use_private_load_balancer ? aws_route53_zone.private[0].zone_id : ""
  description = "The hosted zone id of the private zone for the internal load balancer, if a private zone exists"
}