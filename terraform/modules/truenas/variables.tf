variable "dataset_defaults" {
  type = object({
    description        = string
    pool               = string
    atime              = string
    case_sensitivity   = string
    compression        = string
    copies             = number
    deduplication      = string
    exec               = string
    readonly           = string
    record_size        = string
    snap_dir           = string
    sync               = string
    encryption         = string
    quota_bytes        = number
    quota_critical     = number
    quota_warning      = number
    ref_quota_bytes    = number
    ref_quota_critical = number
    ref_quota_warning  = number
  })
}

variable "encryption_key" {
  type      = string
  sensitive = true
}

variable "datasets" {
  type = list(object({
    path               = string
    description        = optional(string)
    pool               = optional(string)
    atime              = optional(string)
    case_sensitivity   = optional(string)
    compression        = optional(string)
    copies             = optional(number)
    deduplication      = optional(string)
    exec               = optional(string)
    readonly           = optional(string)
    record_size        = optional(string)
    snap_dir           = optional(string)
    sync               = optional(string)
    encryption         = optional(string)
    quota_bytes        = optional(number)
    quota_critical     = optional(number)
    quota_warning      = optional(number)
    ref_quota_bytes    = optional(number)
    ref_quota_critical = optional(number)
    ref_quota_warning  = optional(number)
  }))
}
