# K3s on TrueNAS SCALE

Few config changes not available in the UI yet:

```sh
incus config set knas01 security.nesting=true
incus config device add knas01 kmsg unix-char path=/dev/kmsg
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
