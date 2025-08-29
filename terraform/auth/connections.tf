resource "auth0_connection" "github" {
  name     = "GitHub"
  strategy = "github"

  options {
    scopes        = ["email", "profile"]
    client_id     = data.doppler_secrets.colvin.map.GITHUB_AUTH_CLIENT_ID
    client_secret = data.doppler_secrets.colvin.map.GITHUB_AUTH_CLIENT_SECRET
  }
}
