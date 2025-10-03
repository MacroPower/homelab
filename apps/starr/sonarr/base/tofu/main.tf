variable "sonarr_auth_apikey" {
  type      = string
  sensitive = true
}

resource "sonarr_media_management" "tv" {
  # Folders
  create_empty_folders = false
  delete_empty_folders = true

  # Importing
  episode_title_required = "always"
  enable_media_info      = true
  skip_free_space_check  = true
  minimum_free_space     = 100
  hardlinks_copy         = false
  import_extra_files     = true
  extra_file_extensions  = "srt,sub,info"

  # File Management
  unmonitor_previous_episodes = false
  download_propers_repacks    = "preferAndUpgrade"
  rescan_after_refresh        = "always"
  file_date                   = "none"
  recycle_bin_path            = ""
  recycle_bin_days            = 7

  # Permissions
  set_permissions = false
  chmod_folder    = "755"
  chown_group     = ""
}

resource "sonarr_root_folder" "tv" {
  path = "/media/video/tv/library/"
}

resource "sonarr_download_client_qbittorrent" "tv" {
  enable = true
  name   = "qBittorrent-TV"
  host   = "qbt-tv-web.starr-qbt-tv.svc.cluster.local"
  port   = 8080

  priority      = 1 # Client Priority
  initial_state = 0 # Start

  remove_completed_downloads = false
  remove_failed_downloads    = false
}

# # https://wiki.servarr.com/en/sonarr/troubleshooting#remote-path-mapping
# resource "sonarr_remote_path_mapping" "tv" {
#   host        = sonarr_download_client_qbittorrent.tv.host
#   remote_path = "/downloads/"
#   local_path  = "/media/video/tv/downloads/"
# }

resource "sonarr_download_client_config" "tv" {
  enable_completed_download_handling = true
  auto_redownload_failed             = false
}
