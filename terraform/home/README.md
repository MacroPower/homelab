# Terraform (Home)

## Bootstrap

### Mikrotik

1. Set network interface to 192.168.88.10/24
2. Navigate to 192.168.88.1
3. Set Address Acquisition to Automatic
4. Reboot

You then need to do a partial apply to bootstrap TLS.

```sh
terraform apply -target=module.mikrotik_agg_api
```

### TrueNAS

1. DEL (Enter BIOS)
    - Set time to UTC
2. Network -> Global Configuration -> Settings
    - Set hostname
    - Check "Inherit domain from DHCP"
3. System Settings -> Services -> SSH
    - Check "Log in as Root with Password"
    - Check "Allow Password Authentication"
    - Uncheck Start Automatically
    - Start the SSH service
    - Once provisioning is complete, SSH can be disabled
4. Apps
    - Choose a pool for Apps
