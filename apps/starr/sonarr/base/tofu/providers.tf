terraform {
  backend "kubernetes" {
    secret_suffix     = "providerconfig"
    namespace         = "starr-sonarr"
    in_cluster_config = true
  }
  required_providers {
    sonarr = {
      source = "devopsarr/sonarr"
      version = "3.4.1"
    }
  }
}

provider "sonarr" {
  url     = "http://sonarr.starr-sonarr.svc.cluster.local:8989"
  api_key = file("${path.module}/sonarr-apikey")
}
