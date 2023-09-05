# Hetzner Robot

## K3S

See [home/README.md](../home/README.md) for details.

### Setup

Your server needs to be in the rescue system to begin, with a public key added
such that Terraform can login using the provided SSH key.

If you have multiple nodes, this may not work. You probably will need a vSwitch
at least.

### Disk Setup

Disks (other than the OS disk) are not managed by any kind of automation.

This is what I did with two disks.

Create partitions:

```sh
fdisk /dev/sda # g, n, keep defaults, w
fdisk /dev/sdb
```

Create directories for mounts:

```sh
mkdir /mnt/disk1
mkdir /mnt/disk2
```

Create btrfs filesystem:

```sh
mkfs.btrfs /dev/sda1
mkfs.btrfs /dev/sdb1
```

Get and note the UUID:

```sh
btrfs filesystem show /dev/sda1
btrfs filesystem show /dev/sdb1
```

Edit /etc/fstab:

```sh
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1 btrfs defaults 0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2 btrfs defaults 0 0
```

Test changes:

```sh
mount -a
```

Create subvolumes:

```sh
btrfs subvolume create /mnt/disk1/tv
btrfs subvolume create /mnt/disk1/music
btrfs subvolume create /mnt/disk1/audio
btrfs subvolume create /mnt/disk2/anime
btrfs subvolume create /mnt/disk2/movies
```

Edit /etc/fstab:

```sh
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1        btrfs defaults               0 0
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1/tv     btrfs defaults,subvol=tv     0 0
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1/music  btrfs defaults,subvol=music  0 0
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1/audio  btrfs defaults,subvol=audio  0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2        btrfs defaults               0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2/anime  btrfs defaults,subvol=anime  0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2/movies btrfs defaults,subvol=movies 0 0
```

Test changes:

```sh
mount -a
```
