locals {
  tls_service = { "api-ssl" = 8729, "www-ssl" = 443 }
}

resource "routeros_system_certificate" "crt" {
  name             = "self-signed"
  common_name      = var.name
  key_size         = "4096"
  days_valid       = 3650
  subject_alt_name = "DNS:${var.name},IP:${var.ipv4}"
  trusted          = true

  sign {}
}

resource "routeros_ip_service" "tls" {
  for_each    = local.tls_service
  numbers     = each.key
  port        = each.value
  certificate = routeros_system_certificate.crt.name
  tls_version = "only-1.2"
  disabled    = false
}

resource "routeros_system_identity" "identity" {
  name = var.name
}
