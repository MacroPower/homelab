# Fetch secrets from Doppler
data "doppler_secrets" "this" {
  project = "cloudflare"
  config  = "jacobcolvin-com_git"
}

locals {
  account_id = data.doppler_secrets.this.map.ACCOUNT_ID
  zone_id    = data.doppler_secrets.this.map.DNS_ZONE_ID
}

# Cloudflare Worker script
resource "cloudflare_workers_script" "git_proxy" {
  account_id     = local.account_id
  script_name    = "git-proxy"
  content_file   = "${path.module}/worker.js"
  content_sha256 = filesha256("${path.module}/worker.js")
  main_module    = "worker.js"
}

# Bind custom domains to the worker
resource "cloudflare_workers_custom_domain" "go" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "go.jacobcolvin.com"
  service    = cloudflare_workers_script.git_proxy.script_name
}

resource "cloudflare_workers_custom_domain" "tap" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "tap.jacobcolvin.com"
  service    = cloudflare_workers_script.git_proxy.script_name
}

resource "cloudflare_workers_custom_domain" "git" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "git.jacobcolvin.com"
  service    = cloudflare_workers_script.git_proxy.script_name
}

resource "cloudflare_workers_custom_domain" "nur" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "nur.jacobcolvin.com"
  service    = cloudflare_workers_script.git_proxy.script_name
}

resource "cloudflare_workers_custom_domain" "oci" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "oci.jacobcolvin.com"
  service    = cloudflare_workers_script.git_proxy.script_name
}
