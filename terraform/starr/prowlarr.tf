provider "prowlarr" {
  url     = "http://prowlarr.servarr.svc.cluster.local:9696"
  api_key = file("${path.module}/prowlarr-apikey")
}

terraform {
  required_providers {
    prowlarr = {
      source = "devopsarr/prowlarr"
      version = "2.4.3"
    }
  }
}

variable "radarr_api_key" {
  type      = string
  sensitive = true
}

variable "transmission_movies_rpc_password" {
  type      = string
  sensitive = true
}

locals {
  movie_categories = [
    2000, # Movies
    2010, # Movies/Foreign
    2020, # Movies/Other
    2030, # Movies/SD
    2040, # Movies/HD
    2045, # Movies/UHD
    2050, # Movies/BluRay
    2060, # Movies/3D
    2070, # Movies/DVD
    2080, # Movies/WEB-DL
    2090, # Movies/x265
  ]
}

resource "prowlarr_application_radarr" "radarr" {
  name            = "Radarr"
  sync_level      = "fullSync"
  base_url        = "http://radarr.servarr.svc:7878"
  prowlarr_url    = "http://prowlarr.servarr.svc:9696"
  api_key         = var.radarr_api_key
  sync_categories = local.movie_categories
}

resource "prowlarr_download_client_transmission" "movies_client" {
  enable     = false
  add_paused = true

  name       = "Transmission Movies"
  host       = "transmission-movies.transmission.svc"
  port       = 9091
  username   = ""
  password   = var.transmission_movies_rpc_password
  category   = "Movies"
  categories = [{
    name       = "Movies"
    categories = local.movie_categories
  }]
}
