# Talos Disks

## Removing Partitions

Reset a node (enters maintenance mode):

```sh
task talos:reset-node CLUSTER_NAME=main NODE=knode
```

Get discovered volumes (disks and partitions):

```sh
talosctl get discoveredvolumes -n knode.cin.macro.network --insecure
```

Wipe and drop a partition:

```sh
talosctl wipe disk nvme0n1p<n> -n knode.cin.macro.network --insecure --drop-partition
```

Re-apply the initial machine config:

```sh
task talos:apply-insecure CLUSTER_NAME=main MODE=auto NODE=knode
```

Verify that the volumes have been updated correctly:

```sh
talosctl get discoveredvolumes -n knode.cin.macro.network
```
