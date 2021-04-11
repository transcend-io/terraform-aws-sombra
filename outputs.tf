output "internal_url" {
  value       = "https://${var.subdomain}.${var.root_domain}:${var.internal_port}"
  description = "Url of the internal sombra service. Depending on settings, it may only be accessible inside the VPC"
}

output "external_url" {
  value       = "https://${var.subdomain}.${var.root_domain}:${var.external_port}"
  description = "Url of the external sombra service. It is publically accessible"
}

output "private_zone_id" {
  value       = module.load_balancer.private_zone_id
  description = "The hosted zone id of the private zone for the internal load balancer, if a private zone exists"
}

output "internal_listener_arn" {
  value       = module.load_balancer.internal_listener_arn
  description = "ARN of the internal sombra load balancer listener"
}

output "external_listener_arn" {
  value       = module.load_balancer.external_listener_arn
  description = "ARN of the external sombra load balancer listener"
}

output "lb_arn_suffix" {
  value       = module.load_balancer.arn_suffix
  description = "Amazon Resource Name suffix for the load balancer. Only present in single alb configurations"
}

output "role_arn" {
  value       = module.service.role_arn
  description = "Arn of the task execution role"
}

output "policy_arns" {
  value       = module.service.policy_arns
  description = "Amazon resource names of all policies set on the IAM Role execution task"
}