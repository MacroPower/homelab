resource "auth0_custom_domain" "auth_jacobcolvin_com" {
  domain     = "auth.jacobcolvin.com"
  type       = "auth0_managed_certs"
  tls_policy = "recommended"
}

resource "cloudflare_dns_record" "auth_jacobcolvin_com" {
  zone_id  = data.doppler_secrets.colvin.map.CLOUDFLARE_DNS_ZONE_ID
  name     = trimsuffix(auth0_custom_domain.auth_jacobcolvin_com.verification[0].methods[0].domain, ".jacobcolvin.com")
  content  = auth0_custom_domain.auth_jacobcolvin_com.verification[0].methods[0].record
  ttl      = 300
  type     = "CNAME"
  comment  = "Auth0 Custom Domain"
  proxied  = false
  provider = cloudflare.dns

  lifecycle {
    ignore_changes = [ comment_modified_on ]
  }
}

resource "auth0_custom_domain_verification" "auth_jacobcolvin_com_verification" {
  depends_on = [cloudflare_dns_record.auth_jacobcolvin_com]

  custom_domain_id = auth0_custom_domain.auth_jacobcolvin_com.id

  timeouts {
    create = "15m"
  }
}
