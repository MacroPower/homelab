resource "auth0_client" "opencloud_client" {
  name        = "OpenCloud"
  description = "OpenCloud"
  app_type    = "spa"
  callbacks = [
    "https://opencloud.main.cin.macro.network/",
    "https://opencloud.main.cin.macro.network/oidc-callback.html",
    "https://opencloud.main.cin.macro.network/oidc-silent-redirect.html",
  ]
  allowed_logout_urls = [
    "https://opencloud.main.cin.macro.network/",
  ]

  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client_credentials" "opencloud_public" {
  client_id = auth0_client.opencloud_client.id

  authentication_method = "none"
}

resource "auth0_connection_client" "opencloud_client_github_connection" {
  connection_id = auth0_connection.github.id
  client_id     = auth0_client.opencloud_client.id
}

resource "doppler_secret" "opencloud_client_id" {
  name     = "OPENCLOUD_AUTH0_CLIENT_ID"
  value    = auth0_client.opencloud_client.client_id
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}

resource "auth0_role" "opencloud_admin" {
  name        = "opencloudAdmin"
  description = "OpenCloud Admin"
}

resource "auth0_role" "opencloud_space_admin" {
  name        = "opencloudSpaceAdmin"
  description = "OpenCloud Space Admin"
}

resource "auth0_role" "opencloud_user" {
  name        = "opencloudUser"
  description = "OpenCloud User"
}

resource "auth0_role" "opencloud_guest" {
  name        = "opencloudGuest"
  description = "OpenCloud Guest"
}
