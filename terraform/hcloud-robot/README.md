# Hetzner Robot

## K3S

### Setup

Your server needs to be in the rescue system to begin, with a public key added
such that Terraform can login using the provided SSH key.

If you have multiple nodes, this may not work. You probably will need a vSwitch
at least.

With larger nodes, the default partitions may be too small for the amount of
images/etc on each node, and your node experience DiskPressure. This will result
in the node trying to free space, which it likely won't be able to do. In this
case, you can resize:

```sh
btrfs filesystem resize +10g /var
```
