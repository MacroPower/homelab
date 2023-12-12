mikrotik_devices = {
  agg = {
    name = "mikrotik-agg.home.macro.network"
    ipv4 = "10.0.1.1"
    username = "${MIKROTIK_AGG_USERNAME}"
    password = "${MIKROTIK_AGG_PASSWORD}"
  }
}

truenas_devices = {
  store01 = {
    name = "store01.home.macro.network"
    ipv4 = "10.0.3.2"
    ssh_password = "${STORE01_SSH_PASSWORD}"
    apikey = "${STORE01_APIKEY}"
  }
}

doppler_token = "${STORE01_DOPPLER_TOKEN}"
