set -euo pipefail

VOLUME_LABEL="r-zfs-pool"
POOL_NAME="tank"

echo "Looking for partition with label: $VOLUME_LABEL"
DEVICE_PATH=""

ls -l /dev/disk/by-partlabel/

# Find device by label using /dev/disk/by-partlabel
if [ -L "/dev/disk/by-partlabel/$VOLUME_LABEL" ]; then
  DEVICE_PATH=$(readlink -f "/dev/disk/by-partlabel/$VOLUME_LABEL")
  echo "Found device: $DEVICE_PATH"
else
  echo "No device found with label '$VOLUME_LABEL'"
  exit 0  # Exit gracefully if no device found
fi

echo "Installing required packages..."
apt-get update && apt-get install -y zfsutils-linux kmod util-linux

echo "Loading ZFS kernel module..."
modprobe zfs || echo "ZFS module may already be loaded"

# Check if ZFS pool already exists on this device
if zpool status "$POOL_NAME" >/dev/null 2>&1; then
  echo "ZFS pool '$POOL_NAME' already exists"
  exit 0
fi

# Check if device is already part of any ZFS pool
if zpool labelclear -f "$DEVICE_PATH" 2>/dev/null; then
  echo "Cleared existing ZFS labels from $DEVICE_PATH"
fi

# Create ZFS pool
echo "Creating ZFS pool '$POOL_NAME' on device $DEVICE_PATH"
zpool create -f "$POOL_NAME" "$DEVICE_PATH"

# Verify pool creation
if zpool status "$POOL_NAME"; then
  echo "Successfully created ZFS pool '$POOL_NAME'"
  zpool list "$POOL_NAME"
else
  echo "Failed to create ZFS pool"
  exit 1
fi

echo "ZFS pool setup completed"
