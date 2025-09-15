resource "auth0_client" "lab_admin_client" {
  name        = "Lab (Admin)"
  description = "Lab Apps (Admin)"
  app_type    = "regular_web"
  callbacks = [
    "https://*.main.cin.macro.network/oauth2/callback",
    "https://*.mgmt.cin.macro.network/oauth2/callback",
  ]

  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client_credentials" "lab_admin_client_secret_post" {
  client_id = auth0_client.lab_admin_client.id

  authentication_method = "client_secret_post"
}

resource "auth0_connection_client" "lab_admin_client_github_connection" {
  connection_id = auth0_connection.github.id
  client_id     = auth0_client.lab_admin_client.id
}

resource "doppler_secret" "lab_admin_client_id" {
  name     = "LAB_ADMIN_AUTH0_CLIENT_ID"
  value    = auth0_client.lab_admin_client.client_id
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}

resource "doppler_secret" "lab_admin_client_secret" {
  name     = "LAB_ADMIN_AUTH0_CLIENT_SECRET"
  value    = auth0_client_credentials.lab_admin_client_secret_post.client_secret
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}
