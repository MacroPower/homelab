variable "radarr_auth_apikey" {
  type      = string
  sensitive = true
}

resource "radarr_root_folder" "movies" {
  path = "/media/video/movies/library"
}

resource "radarr_download_client_qbittorrent" "movies" {
  enable = true
  name   = "qBittorrent-Movies"
  host   = "qbt-movies-web.starr-qbt-movies.svc.cluster.local"
  port   = 8080

  priority      = 1 # Client Priority
  initial_state = 0 # Start

  remove_completed_downloads = false
  remove_failed_downloads    = false
}

# # https://wiki.servarr.com/en/radarr/troubleshooting#remote-path-mapping
# resource "radarr_remote_path_mapping" "movies" {
#   host        = radarr_download_client_qbittorrent.movies.host
#   remote_path = "/downloads/"
#   local_path  = "/media/video/movies/downloads/"
# }

resource "radarr_download_client_config" "movies" {
  check_for_finished_download_interval = 1
  enable_completed_download_handling   = true
  auto_redownload_failed               = false
}
