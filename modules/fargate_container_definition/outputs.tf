output json {
  value = module.definition.json
}

output json_map {
  value = module.definition.json_map
}

output secrets_policy_arn {
  value = aws_iam_policy.secret_access_policy.arn
}

output container_name {
  value = var.name
}

output container_ports {
  value = var.containerPorts
}
