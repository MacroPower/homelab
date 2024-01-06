/*
resource "truenas_dataset" "main" {
  name     = ""
  parent   = ""
  pool     = "main"
  comments = "The main pool"

  ## Choose 'on' to update the access time for files when they are read.
  ## Choose 'off' to prevent producing log traffic when reading files.
  ##
  atime = "off"

  case_sensitivity = "sensitive"

  ## Encode information in less space than the original data occupies. It is
  ## recommended to choose a compression algorithm that balances disk
  ## performance with the amount of saved space.
  ## - "lz4" is generally recommended as it maximizes performance and
  ##   dynamically identifies the best files to compress.
  ## - "gzip" options range from 1 for least compression, best performance,
  ##   through 9 for maximum compression with greatest performance impact.
  ## - "zle" is a fast algorithm that only elminates runs of zeroes.
  ##
  compression = "lz4"

  ## Set the number of data copies on this dataset.
  ##
  copies = 1

  ## Transparently reuse a single copy of duplicated data to save space.
  ## Deduplication can improve storage capacity, but is RAM intensive.
  ## Compressing data is generally recommended before using deduplication.
  ## Deduplicating data is a one-way process. Deduplicated data cannot be
  ## undeduplicated!
  ##
  deduplication = "off"

  ## Set whether processes can be executed from within this dataset.
  ##
  exec = "on"

  ## Set to prevent the dataset from being modified.
  ##
  readonly = "off"

  ## Matching the fixed size of data, as in a database, may result in better
  ## performance.
  ##
  record_size = "128K"

  ## Choose if the .zfs snapshot directory is Visible or Invisible on this
  ## dataset.
  ##
  snap_dir = "hidden"

  encrypted = false
  # encryption_algorithm = "AES-256-CCM"
  # encryption_key       = "3e10193aa02f4167edc46c9f4b8ba723eed474deede646fded99628de1878d51"
  # generate_key         = false
  # pbkdf2iters          = 0
  # inherit_encryption   = false

  ## Sets the data write synchronization.
  ## - "inherit" takes the sync settings from the parent dataset.
  ## - "standard" uses the settings that have been requested by the client software.
  ## - "always" waits for data writes to complete.
  ## - "disabled" never waits for writes to complete.
  ##
  sync = "standard"

  timeouts {}

  provider = truenas.nas01

  lifecycle {
    prevent_destroy = true
  }
}
*/

locals {
  nas01_datasets = {
    ix-applications = {}

    backups = {
      datasets = {
        archive = {}
        repos = {
          comments = "Restic repositories"
        }
        youtube = {}
      }
    }

    documents = {
      datasets = {
        books     = {}
        magazines = {}
        media = {
          comments = "Photos and home videos"
        }
        memes  = {}
        school = {}
      }
    }

    documents_secure = {
      encrypted = true
      datasets = {
        finance = {}
      }
    }

    media = {
      datasets = {
        anime = {}
        audio = {
          comments = "Audiobooks and podcasts"
        }
        movies = {}
        music  = {}
        tv     = {}
      }
    }

    public = {
      datasets = {
        images = {
          comments = "Public disk images"
        }
      }
    }

    private = {
      encrypted = true

      datasets = {
        vault = {
          comments = "???"
        }
      }
    }
  }
}
