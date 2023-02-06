// github_release for kured
data "github_release" "kured" {
  count       = var.kured_version == null ? 1 : 0
  repository  = "kured"
  owner       = "weaveworks"
  retrieve_by = "latest"
}
