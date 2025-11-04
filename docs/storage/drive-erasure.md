# Drive Erasure

My "good enough" methods.

## HDD

```sh
dd bs=1M status=progress oflag=direct conv=fsync if=/dev/zero of=/dev/sdX
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
nvme format -s2 /dev/nvme0nX
```

## Verification

```sh
dd if=/dev/sdX bs=1M skip=500000 count=1 | hexdump -C
```

```sh
apt-get install testdisk
sudo photorec
```
