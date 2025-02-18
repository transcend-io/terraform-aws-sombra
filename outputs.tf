output "role_arn" {
  value       = module.service.role_arn
  description = "Arn of the task execution role"
}

output "policy_arns" {
  value       = module.service.policy_arns
  description = "Amazon resource names of all policies set on the IAM Role execution task"
}