# Fetch secrets from Doppler
data "doppler_secrets" "this" {
  project = "cloudflare"
  config  = "jacobcolvin-com_git"
}

locals {
  account_id = data.doppler_secrets.this.map.ACCOUNT_ID
  zone_id    = data.doppler_secrets.this.map.DNS_ZONE_ID

  worker_script = <<-JS
    export default {
      async fetch(request) {
        const url = new URL(request.url);
        const githubUrl = `https://github.com/MacroPower$${url.pathname}$${url.search}`;

        const response = await fetch(githubUrl, {
          method: request.method,
          headers: request.headers,
          body: request.body,
          redirect: 'follow',
        });

        return new Response(response.body, {
          status: response.status,
          headers: response.headers,
        });
      }
    }
  JS
}

# Write worker script to a local file for content_file reference
resource "local_file" "worker_script" {
  content  = local.worker_script
  filename = "${path.module}/worker.js"
}

# Cloudflare Worker script
resource "cloudflare_workers_script" "git_proxy" {
  account_id   = local.account_id
  script_name  = "git-proxy"
  content_file = local_file.worker_script.filename
  main_module  = "worker.js"

  depends_on = [local_file.worker_script]
}

# Bind custom domain to the worker
resource "cloudflare_workers_custom_domain" "git_proxy" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "git.jacobcolvin.com"
  service    = cloudflare_workers_script.git_proxy.script_name
}
