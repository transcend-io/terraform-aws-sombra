output internal_url {
  value = "https://${aws_route53_record.alb_alias.name}:${var.internal_port}"
}

output external_url {
  value = "https://${aws_route53_record.alb_alias.name}:${var.external_port}"
}
