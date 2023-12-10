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
