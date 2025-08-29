resource "auth0_connection" "github" {
  name     = "GitHub"
  strategy = "github"

  options {
    scopes = ["email", "profile"]
  }
}
