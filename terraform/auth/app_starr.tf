# https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/auth0/
resource "auth0_client" "starr_client" {
  name        = "Starr"
  description = "Starr Apps"
  app_type    = "regular_web"
  callbacks = [
    "https://*.main.cin.macro.network/oauth2/callback",
    "https://*.mgmt.cin.macro.network/oauth2/callback",
  ]

  jwt_configuration {
    alg = "RS256"
  }
}

# https://registry.terraform.io/providers/auth0/auth0/latest/docs/resources/client_credentials
resource "auth0_client_credentials" "starr_client_secret_post" {
  client_id = auth0_client.starr_client.id

  authentication_method = "client_secret_post"
}

resource "auth0_connection_client" "starr_client_github_connection" {
  connection_id = auth0_connection.github.id
  client_id     = auth0_client.starr_client.id
}

resource "doppler_secret" "starr_client_id" {
  name     = "STARR_AUTH0_CLIENT_ID"
  value    = auth0_client.starr_client.client_id
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}

resource "doppler_secret" "starr_client_secret" {
  name     = "STARR_AUTH0_CLIENT_SECRET"
  value    = auth0_client_credentials.starr_client_secret_post.client_secret
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}
