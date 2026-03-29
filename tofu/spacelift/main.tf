# Fetch scoped Doppler tokens for child stacks
data "doppler_secrets" "spacelift" {
  project = "spacelift"
  config  = "root"
}

# Cloudflare space for Cloudflare-related stacks
resource "spacelift_space" "cloudflare" {
  name             = "cloudflare"
  parent_space_id  = "root"
  description      = "Space for Cloudflare infrastructure"
  inherit_entities = true
}

# Git proxy worker stack
resource "spacelift_stack" "git_proxy" {
  name        = "git-proxy"
  description = "Cloudflare Worker that proxies git.jacobcolvin.com to github.com/MacroPower"

  space_id                = spacelift_space.cloudflare.id
  project_root            = "tofu/cloudflare/git-proxy"
  repository              = "homelab"
  branch                  = "main"
  autodeploy              = true
  manage_state            = true
  terraform_workflow_tool = "OPEN_TOFU"
}

# Inject scoped Doppler token for git-proxy stack
resource "spacelift_environment_variable" "git_proxy_doppler_token" {
  stack_id   = spacelift_stack.git_proxy.id
  name       = "TF_VAR_doppler_token"
  value      = data.doppler_secrets.spacelift.map.DOPPLER_TOKEN_CLOUDFLARE_JACOBCOLVIN_COM_GIT
  write_only = true
}

# Auth space for Auth0-related stacks
resource "spacelift_space" "auth" {
  name             = "auth"
  parent_space_id  = "root"
  description      = "Space for Auth0 infrastructure"
  inherit_entities = true
}

# Auth0 identity provider stack
resource "spacelift_stack" "auth" {
  name        = "auth"
  description = "Auth0 identity provider configuration"

  space_id                = spacelift_space.auth.id
  project_root            = "tofu/auth"
  repository              = "homelab"
  branch                  = "main"
  autodeploy              = true
  manage_state            = true
  terraform_workflow_tool = "OPEN_TOFU"
}

# Inject scoped Doppler tokens for auth stack
resource "spacelift_environment_variable" "auth_doppler_auth_token" {
  stack_id   = spacelift_stack.auth.id
  name       = "TF_VAR_doppler_auth_token"
  value      = data.doppler_secrets.spacelift.map.DOPPLER_TOKEN_AUTH_COLVIN
  write_only = true
}

resource "spacelift_environment_variable" "auth_doppler_cin_token" {
  stack_id   = spacelift_stack.auth.id
  name       = "TF_VAR_doppler_cin_token"
  value      = data.doppler_secrets.spacelift.map.DOPPLER_TOKEN_HOMELAB_CIN
  write_only = true
}

resource "spacelift_environment_variable" "auth_doppler_cin_mgmt_token" {
  stack_id   = spacelift_stack.auth.id
  name       = "TF_VAR_doppler_cin_mgmt_token"
  value      = data.doppler_secrets.spacelift.map.DOPPLER_TOKEN_HOMELAB_CIN_MGMT
  write_only = true
}
