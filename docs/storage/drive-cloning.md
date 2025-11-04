# Drive Cloning

## Healthy Disks

```sh
dd status=progress conv=fsync if=/dev/sdX of=/mnt/archive/disks/<device>.img
```

## Unhealthy Disks

```sh
ddrescue /dev/sdX /mnt/archive/disks/<device>.img <device>.log
```
