locals {
  MiB = 1024 * 1024
  GiB = 1024 * local.MiB
  TiB = 1024 * local.GiB
}

resource "random_password" "nas01_encryption_key" {
  length      = 64
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "doppler_secret" "nas01_encryption_key" {
  project = "terraform"
  config  = "main_home"
  name    = "NAS01_ENCRYPTION_KEY"
  value   = random_password.nas01_encryption_key.result
}

module "truenas_common" {
  source = "../modules/truenas-common"
}

module "nas01_datasets_primary" {
  source = "../modules/truenas"

  dataset_defaults = module.truenas_common.dataset_defaults
  encryption_key   = doppler_secret.nas01_encryption_key.value

  datasets = [
    {
      path        = "/archive"
      description = "Archives"
      quota_bytes = 50 * local.TiB
    },
    {
      path        = "/home"
      description = "User storage"
      encryption  = "AES-128-GCM"
      quota_bytes = 50 * local.TiB
    },
    {
      path        = "/public"
      description = "Shared user storage"
      encryption  = "AES-128-GCM"
      quota_bytes = 50 * local.TiB
    },
    {
      path        = "/media"
      description = "Public audio, video, literature"
      compression = "off"
      quota_bytes = 50 * local.TiB
    },
    {
      path        = "/software"
      description = "Public applications, firmware, source code, roms, operating systems"
      quota_bytes = 10 * local.TiB
    },
    {
      path        = "/vault"
      description = "Restricted data"
      encryption  = "AES-128-GCM"
      quota_bytes = 50 * local.TiB
    },
    {
      path        = "/jailmaker"
      description = "Jails"
      encryption  = "AES-128-GCM"
      quota_bytes = 1 * local.TiB
    },
    {
      path        = "/system"
      description = "TrueNAS system resources"
      record_size = "128K"
      quota_bytes = 1 * local.GiB
    },
  ]

  providers = { truenas = truenas.nas01 }
}

module "nas01_datasets_secondary" {
  source = "../modules/truenas"

  dataset_defaults = module.truenas_common.dataset_defaults
  encryption_key   = doppler_secret.nas01_encryption_key.value

  datasets = [
    {
      path        = "/archive/backups"
      description = "Restic repositories"
      compression = "off"
    },
    {
      path        = "/archive/disks"
      description = "Disk images"
      encryption  = "AES-128-GCM"
    },
    {
      path        = "/archive/websites"
      description = "Site rips"
    },
    {
      path        = "/media/audio"
      description = "Music, podcasts, audiobooks"
      compression = "off"
    },
    {
      path        = "/media/video"
      description = "Movies, TV, anime, youtube, twitch"
      compression = "off"
    },
    {
      path        = "/media/literature"
      description = "Books, comics, magazines, manga"
      compression = "off"
    },
    # /home/firstlast/documents/school
    # /home/firstlast/documents/work
    # /home/firstlast/documents/finance
    # /home/firstlast/images/artwork
    # /home/firstlast/images/photos
    # /home/firstlast/images/memes
    # /home/firstlast/images/pfps
    # /home/firstlast/screen/captures
    # /home/firstlast/screen/shots
    # /home/firstlast/games/saves
    # /home/firstlast/games/replays
  ]

  providers = { truenas = truenas.nas01 }

  depends_on = [ module.nas01_datasets_primary ]
}
