# Datasets

## Config

Default dataset values:

```py
# Choose 'on' to update the access time for files when they are read.
# Choose 'off' to prevent producing log traffic when reading files.
atime = "off"

# Choose 'sensitive' to make file and directory names case-sensitive.
# Choose 'insensitive' to make file and directory names case-insensitive.
case_sensitivity = "sensitive"

# Encode information in less space than the original data occupies. It is
# recommended to choose a compression algorithm that balances disk
# performance with the amount of saved space.
# - Use "zstd-fast" for datasets that can be compressed
# - Use "off" for datasets where contents are already effectively compressed
compression = "zstd-fast"

# Set the number of data copies on this dataset.
copies = 1

# Transparently reuse a single copy of duplicated data to save space.
# Deduplication can improve storage capacity, but is RAM intensive.
# Compressing data is generally recommended before using deduplication.
# Deduplicating data is a one-way process. Deduplicated data cannot be
# un-deduplicated!
deduplication = "off"

# on = fletcher4 for non-deduped datasets, sha256 for deduped datasets
checksum = "on"

# Set to prevent the dataset from being modified.
readonly = "off"

# Set whether processes can be executed from within this dataset.
exec = "on"

# Matching the fixed size of data, as in a database, may result in better performance.
# Datasets with large files only (e.g. media) use 1M.
record_size = "128K"

# Choose if the .zfs snapshot directory is Visible or Invisible on this dataset.
snap_dir = "invisible"

# Choose whether the volume snapshot devices under /dev/zvol/{pool} are hidden or visible.
snap_dev = "hidden"

# Choose the encryption algorithm to use.
# - "AES-128-GCM"
# - "AES-192-GCM"
# - "AES-256-GCM"
encryption = "off"

# Sets the data write synchronization.
# - "inherit" takes the sync settings from the parent dataset.
# - "standard" uses the settings that have been requested by the client software.
# - "always" waits for data writes to complete.
# - "disabled" never waits for writes to complete.
sync = "standard"

acl_type = "posix"

quota_bytes = 0
ref_quota_bytes = 0
quota_critical = 90
quota_warning = 70
ref_quota_critical = 90
ref_quota_warning = 70
```
