# Hetzner Robot

## Setup

Your server needs to be in the rescue system to begin, with a public key added
such that Terraform can login using the provided SSH key.

If you have multiple nodes, this may not work. You probably will need a vSwitch
at least.

## Disk Setup

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
btrfs subvolume create /mnt/ssd1/pgdb
btrfs subvolume create /mnt/ssd1/ak-pgdb
btrfs subvolume create /mnt/ssd1/ak-redis
```

Edit /etc/fstab:

```sh
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1         btrfs defaults                 0 0
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1/tv      btrfs defaults,subvol=tv       0 0
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1/music   btrfs defaults,subvol=music    0 0
UUID=b5570ff7-e9bf-41d7-a1cd-f4cb353d6879 /mnt/disk1/audio   btrfs defaults,subvol=audio    0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2         btrfs defaults                 0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2/anime   btrfs defaults,subvol=anime    0 0
UUID=55d3afc8-696b-4a00-8397-e0927388399e /mnt/disk2/movies  btrfs defaults,subvol=movies   0 0
UUID=0c69f3b7-8635-4681-8ed4-ca9f5633d346 /mnt/ssd1          btrfs defaults                 0 0
UUID=0c69f3b7-8635-4681-8ed4-ca9f5633d346 /mnt/ssd1/pgdb     btrfs defaults,subvol=pgdb     0 0
UUID=0c69f3b7-8635-4681-8ed4-ca9f5633d346 /mnt/ssd1/ak-pgdb  btrfs defaults,subvol=ak-pgdb  0 0
UUID=0c69f3b7-8635-4681-8ed4-ca9f5633d346 /mnt/ssd1/ak-redis btrfs defaults,subvol=ak-redis 0 0
```

Test changes:

```sh
mount -a
```

## Disk sizing

With larger nodes, the default partitions may be too small for the amount of
images/etc on each node, and your node experience DiskPressure. This will result
in the node trying to free space, which it likely won't be able to do. In this
case, you can resize:

```sh
btrfs filesystem resize +10g /var
```

Parted can be helpful outside btrfs:

```sh
transactional-update shell <<<"zypper install parted"
```

## Upgrades

For single node clusters, you need to run upgrades manually.

Upgrade MicroOS:

```sh
transactional-update
reboot
```

Upgrade K3s:

Note that you don't need to use transactional-update for this. The k3s script
will do it for you.

```sh
curl -sfL https://get.k3s.io | sh -
reboot
```

[kube-hetzner]: https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner
[microos-dl]: https://en.opensuse.org/Portal:MicroOS/Downloads
