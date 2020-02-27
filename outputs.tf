output internal_url {
  value = "https://${var.subdomain}.${var.root_domain}:${var.internal_port}"
  description = "Url of the internal sombra service. Depending on settings, it may only be accessible inside the VPC"
}

output external_url {
  value = "https://${var.subdomain}.${var.root_domain}:${var.external_port}"
  description = "Url of the external sombra service. It is publically accessible"
}
