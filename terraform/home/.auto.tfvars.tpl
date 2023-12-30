truenas_devices = {
  nas01 = {
    fqdn         = "nas01.home.macro.network"
    ipv4         = "10.10.1.1"
    ssh_password = "${NAS01_SSH_PASSWORD}"
    apikey       = "${NAS01_APIKEY}"
  }
}

unifi_sites = {
  home = {
    username    = "${UNIFI_USERNAME}"
    password    = "${UNIFI_PASSWORD}"
    api_url     = "https://unifi.home.macro.network"
    site        = "default"
    domain_name = "home.macro.network"
  }
}

doppler_token = "${NAS01_DOPPLER_TOKEN}"
