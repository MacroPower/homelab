// github_release for kured
data "github_release" "kured" {
  repository  = "kured"
  owner       = "weaveworks"
  retrieve_by = "latest"
}
