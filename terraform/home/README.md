# Home

## K3s

This runs a vastly simplified version of [kube-hetzner][kube-hetzner], made to
work on local nodes that are already mostly configured.

I would not recommend trying to install extras like Longhorn via the k3s module,
it probably won't work.

### Setup

Install MicroOS [https://en.opensuse.org/Portal:MicroOS/Downloads][microos-dl]

Everything can be left default, except:

Select "Container host" as the role.

Do not set any root password, do the following instead:

Create an SSH key for Terraform:

```sh
ssh-keygen -t ecdsa -b 521 -f microos -C "username@domain"
```

Simply use this SSH public key instead of a password. You can do this by copying
the SSH public key to a flash drive and making sure it's available during
installation. You can press CTRL+ALT+F2 to enter a shell if it doesn't mount.
You can press ALT+F7 to re-enter the graphical installer.

On my unraid server, I instead added a share for keys and then mounted it:

```sh
mkdir /mnt/<name>
mount -t 9p <unraid tag> /mnt/<name>
```

Later, you can configure your personal SSH key, plus any others, as SSH
authorized keys. This means you won't have to have your other SSH key(s) stored
in TF vars or the TF state.

[kube-hetzner]: https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner
[microos-dl]: https://en.opensuse.org/Portal:MicroOS/Downloads
