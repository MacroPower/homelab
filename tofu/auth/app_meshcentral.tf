resource "auth0_client" "meshcentral_client" {
  name        = "MeshCentral"
  description = "MeshCentral"
  app_type    = "regular_web"
  callbacks   = ["https://meshcentral.jacobcolvin.com/auth-oidc-callback"]

  jwt_configuration {
    alg = "RS256"
  }

  oidc_logout {
    backchannel_logout_urls = []

    backchannel_logout_initiators {
      mode                = "custom"
      selected_initiators = ["idp-logout", "rp-logout"]
    }
  }
}

resource "auth0_client_credentials" "meshcentral_client_secret_post" {
  client_id = auth0_client.meshcentral_client.id

  authentication_method = "client_secret_post"
}

resource "auth0_connection_client" "meshcentral_client_github_connection" {
  connection_id = auth0_connection.github.id
  client_id     = auth0_client.meshcentral_client.id
}

resource "doppler_secret" "meshcentral_client_id" {
  name     = "MESHCENTRAL_AUTH0_CLIENT_ID"
  value    = auth0_client.meshcentral_client.client_id
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}

resource "auth0_role" "meshcentral_admin" {
  name        = "meshcentral-admin"
  description = "MeshCentral Admin"
}

resource "auth0_role" "meshcentral_user" {
  name        = "meshcentral-user"
  description = "MeshCentral User"
}

resource "doppler_secret" "meshcentral_client_secret" {
  name     = "MESHCENTRAL_AUTH0_CLIENT_SECRET"
  value    = auth0_client_credentials.meshcentral_client_secret_post.client_secret
  project  = "homelab"
  config   = "cin"
  provider = doppler.cin
}
