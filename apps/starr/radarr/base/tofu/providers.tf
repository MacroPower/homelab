terraform {
  backend "kubernetes" {
    secret_suffix     = "providerconfig"
    namespace         = "starr-radarr"
    in_cluster_config = true
  }
  required_providers {
    radarr = {
      source = "devopsarr/radarr"
      version = "2.3.3"
    }
  }
}

provider "radarr" {
  url     = "http://radarr.starr-radarr.svc.cluster.local:7878"
  api_key = file("${path.module}/radarr-apikey")
}
