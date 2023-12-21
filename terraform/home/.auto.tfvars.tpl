truenas_devices = {
  store01 = {
    name = "store01.home.macro.network"
    ipv4 = "10.0.3.2"
    ssh_password = "${STORE01_SSH_PASSWORD}"
    apikey = "${STORE01_APIKEY}"
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

doppler_token = "${STORE01_DOPPLER_TOKEN}"
