# K3s on TrueNAS SCALE

Few config changes not available in the UI yet:

```sh
incus config set knas01 security.nesting=true
incus config set knas01 security.privileged=true
incus config set knas01 linux.kernel_modules=overlay,iptable_nat,iptable_mangle,iptable_raw,iptable_filter,ip6_tables,ip6table_mangle,ip6table_raw,ip6table_filter,xt_socket
incus config device add knas01 kmsg unix-char path=/dev/kmsg
incus config device add knas01 sysbpf disk source=/sys/fs/bpf path=/sys/fs/bpf

incus restart knas01
```

When getting a shell, fix the path so that nix works properly:

```sh
PATH=$PATH:/run/current-system/sw/bin/
bash
```

Initial setup:

```sh
nix-channel --update

# Edit /etc/nixos/configuration.nix

nixos-rebuild switch
```
