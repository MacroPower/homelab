# https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/auth0/
resource "auth0_client" "argo_cd_client" {
  name                = "Argo CD"
  description         = "Argo CD"
  app_type            = "spa"
  initiate_login_uri = "https://argo-cd.jacobcolvin.com/login"
  callbacks           = ["https://argo-cd.jacobcolvin.com/auth/callback"]

  jwt_configuration {
    alg = "RS256" # Argo supports "PS256" but free auth0 doesn't.
  }
}

# https://registry.terraform.io/providers/auth0/auth0/latest/docs/resources/client_credentials
resource "auth0_client_credentials" "argo_cd_client_secret_post" {
  client_id = auth0_client.argo_cd_client.id

  authentication_method = "client_secret_post"
}

resource "auth0_connection_client" "argo_cd_client_github_connection" {
  connection_id = auth0_connection.github.id
  client_id     = auth0_client.argo_cd_client.id
}

resource "doppler_secret" "argo_cd_client_id" {
  name     = "ARGO_CD_AUTH0_CLIENT_ID"
  value    = auth0_client.argo_cd_client.client_id
  project  = "homelab"
  config   = "cin_mgmt"
  provider = doppler.cin_mgmt
}

resource "doppler_secret" "argo_cd_client_secret" {
  name     = "ARGO_CD_AUTH0_CLIENT_SECRET"
  value    = auth0_client_credentials.argo_cd_client_secret_post.client_secret
  project  = "homelab"
  config   = "cin_mgmt"
  provider = doppler.cin_mgmt
}

resource "auth0_role" "argo_cd_admin" {
  name        = "argo-cd-admin"
  description = "Argo CD Admin"
}
