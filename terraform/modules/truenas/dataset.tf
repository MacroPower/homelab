resource "truenas_dataset" "dataset" {
  for_each = {
    for k, v in var.datasets :
      join("/", [coalesce(v.pool, var.dataset_defaults.pool), trim(v.path, "/")]) => merge(v, {
        parts              = split("/", trim(v.path, "/"))
        description        = coalesce(v.description, var.dataset_defaults.description)
        pool               = coalesce(v.pool, var.dataset_defaults.pool)
        atime              = coalesce(v.atime, var.dataset_defaults.atime)
        case_sensitivity   = coalesce(v.case_sensitivity, var.dataset_defaults.case_sensitivity)
        compression        = coalesce(v.compression, var.dataset_defaults.compression)
        copies             = coalesce(v.copies, var.dataset_defaults.copies)
        deduplication      = coalesce(v.deduplication, var.dataset_defaults.deduplication)
        exec               = coalesce(v.exec, var.dataset_defaults.exec)
        readonly           = coalesce(v.readonly, var.dataset_defaults.readonly)
        record_size        = coalesce(v.record_size, var.dataset_defaults.record_size)
        snap_dir           = coalesce(v.snap_dir, var.dataset_defaults.snap_dir)
        sync               = coalesce(v.sync, var.dataset_defaults.sync)
        encryption         = coalesce(v.encryption, var.dataset_defaults.encryption)
        quota_bytes        = coalesce(v.quota_bytes, var.dataset_defaults.quota_bytes)
        quota_critical     = coalesce(v.quota_critical, var.dataset_defaults.quota_critical)
        quota_warning      = coalesce(v.quota_warning, var.dataset_defaults.quota_warning)
        ref_quota_bytes    = coalesce(v.ref_quota_bytes, var.dataset_defaults.ref_quota_bytes)
        ref_quota_critical = coalesce(v.ref_quota_critical, var.dataset_defaults.ref_quota_critical)
        ref_quota_warning  = coalesce(v.ref_quota_warning, var.dataset_defaults.ref_quota_warning)
      })
  }

  pool   = each.value.pool
  parent = length(each.value.parts) > 1 ? element(each.value.parts, length(each.value.parts)-2) : ""
  name   = element(each.value.parts, length(each.value.parts)-1)

  comments = each.value.description

  atime                = each.value.atime
  case_sensitivity     = each.value.case_sensitivity
  compression          = each.value.compression
  copies               = each.value.copies
  deduplication        = each.value.deduplication
  exec                 = each.value.exec
  readonly             = each.value.readonly
  record_size          = each.value.record_size
  snap_dir             = each.value.snap_dir
  sync                 = each.value.sync
  encrypted            = each.value.encryption != "off" ? true : false
  encryption_algorithm = each.value.encryption != "off" ? each.value.encryption : null
  generate_key         = each.value.encryption != "off" ? true : null
  quota_bytes          = each.value.quota_bytes
  quota_critical       = each.value.quota_critical
  quota_warning        = each.value.quota_warning
  ref_quota_bytes      = each.value.ref_quota_bytes
  ref_quota_critical   = each.value.ref_quota_critical
  ref_quota_warning    = each.value.ref_quota_warning

  timeouts {}

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [record_size]
  }
}
