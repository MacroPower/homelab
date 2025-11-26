terraform {
  backend "kubernetes" {
    secret_suffix     = "providerconfig"
    namespace         = "starr-prowlarr"
    in_cluster_config = true
  }
  required_providers {
    prowlarr = {
      source = "devopsarr/prowlarr"
      version = "3.1.0"
    }
  }
}

provider "prowlarr" {
  url     = "http://prowlarr.starr-prowlarr.svc.cluster.local:9696"
  api_key = file("${path.module}/prowlarr-apikey")
}
