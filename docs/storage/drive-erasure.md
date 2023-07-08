# Drive Erasure

My "good enough" methods.

## HDD

```sh
dd bs=1M status=progress if=/dev/zero of=/dev/sdX
```

## SATA SSD

```sh
dd bs=1M status=progress if=/dev/urandom of=/dev/sdX
blkdiscard -v -f /dev/sdX
```

## NVMe SSD

```sh
apt-get install nvme-cli
nvme list
nvme format -s1 /dev/nvme0nX
```

## Verification

```sh
debugfs -w /dev/sdX
```
