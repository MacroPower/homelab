variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "public_keys_openssh" {
  type = map(string)
}

# Generate an auth key from the Admin console
# https://login.tailscale.com/admin/settings/keys
variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}
