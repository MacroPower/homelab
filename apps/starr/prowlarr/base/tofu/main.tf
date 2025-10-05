variable "sonarr_auth_apikey" {
  type      = string
  sensitive = true
}

variable "radarr_auth_apikey" {
  type      = string
  sensitive = true
}

variable "avistaz_indexers" {
  type = map(object({
    implementation = string
    base_url = string
    username = string
    password = string
    pid = string
    priority = optional(number, 25)
  }))
  sensitive = true
}

locals {
  prowlarr_url = "http://prowlarr.starr-prowlarr.svc.cluster.local:9696"

  tv_categories = [
    5000, # TV
    5010, # TV/WEB-DL
    5020, # TV/Foreign
    5030, # TV/SD
    5040, # TV/HD
    5045, # TV/UHD
    5050, # TV/Other
    5060, # TV/Sport
    5080, # TV/Documentary
    5090, # TV/x265
  ]

  anime_categories = [
    5070, # TV/Anime
  ]

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

resource "prowlarr_application_sonarr" "sonarr" {
  name                  = "Sonarr"
  sync_level            = "fullSync"
  base_url              = "http://sonarr.starr-sonarr.svc.cluster.local:8989"
  prowlarr_url          = local.prowlarr_url
  api_key               = var.sonarr_auth_apikey
  sync_categories       = local.tv_categories
  anime_sync_categories = local.anime_categories
}

resource "prowlarr_application_radarr" "radarr" {
  name            = "Radarr"
  sync_level      = "fullSync"
  base_url        = "http://radarr.starr-radarr.svc.cluster.local:7878"
  prowlarr_url    = local.prowlarr_url
  api_key         = var.radarr_auth_apikey
  sync_categories = local.movie_categories
}

resource "prowlarr_indexer" "avistaz" {
  for_each = nonsensitive(var.avistaz_indexers)

  enable          = true
  name            = each.key
  implementation  = each.value.implementation
  config_contract = "AvistazSettings"
  app_profile_id  = 1
  priority        = each.value.priority
  protocol        = "torrent"

  fields = [
    {
      name       = "baseUrl"
      text_value = each.value.base_url
    },
    {
      name       = "username"
      text_value = each.value.username
    },
    {
      name            = "password"
      sensitive_value = sensitive(each.value.password)
    },
    {
      name            = "pid"
      sensitive_value = sensitive(each.value.pid)
    },
    {
      name       = "freeleechOnly"
      bool_value = false
    },
    {
      name         = "baseSettings.queryLimit"
      number_value = 2400
    },
    {
      name         = "baseSettings.grabLimit"
      number_value = 48
    },
    {
      name         = "baseSettings.limitsUnit"
      number_value = 0 # Days
    },
    {
      name         = "torrentBaseSettings.appMinimumSeeders"
      number_value = 1
    },
    {
      name         = "torrentBaseSettings.seedRatio"
      number_value = 2
    },
    {
      name         = "torrentBaseSettings.seedTime"
      number_value = 129600
    },
    {
      name         = "torrentBaseSettings.packSeedTime"
      number_value = 129600
    },
    {
      name       = "torrentBaseSettings.preferMagnetUrl"
      bool_value = false
    }
  ]
}

resource "prowlarr_download_client_qbittorrent" "qbt_tv" {
  enable = true
  name   = "qBittorrent-TV"
  host   = "qbt-tv-web.starr-qbt-tv.svc.cluster.local"
  port   = 8080

  priority      = 1 # Client Priority
  item_priority = 0 # Last
  initial_state = 0 # Start
  category      = "tv-prowlarr"
  # categories = [{
  #   name       = "TV"
  #   categories = local.tv_categories
  # }]
}

resource "prowlarr_download_client_qbittorrent" "qbt_movies" {
  enable = true
  name   = "qBittorrent-Movies"
  host   = "qbt-movies-web.starr-qbt-movies.svc.cluster.local"
  port   = 8080

  priority      = 1 # Client Priority
  item_priority = 0 # Last
  initial_state = 0 # Start
  category      = "movies-prowlarr"
  # categories = [{
  #   name       = "Movies"
  #   categories = local.movie_categories
  # }]
}
