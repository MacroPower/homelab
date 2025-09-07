import file

import konfig.models.frontend
import konfig.models.frontend.container
import konfig.models.frontend.secret
import konfig.models.utils
import konfig.files

import external
import charts.external_dns

_values = files.read_yaml(file.current(), "values.yaml")

cloudflareCreds = secret.ExternalSecret {
    name = "cloudflare-credentials"
    data = {
        CLOUDFLARE_API_EMAIL = {}
        CLOUDFLARE_API_TOKEN = {}
    }
}

_cloudflareEnv = container.EnvMap {
    CF_API_EMAIL = cloudflareCreds.getSecretKeyEnvRef("CLOUDFLARE_API_EMAIL")
    CF_API_TOKEN = cloudflareCreds.getSecretKeyEnvRef("CLOUDFLARE_API_TOKEN")
}

cloudflareValues = _values | external_dns.Values {
    nameOverride = "cloudflare"
    provider.name = "cloudflare"
    env = utils.EnvBuilder(_cloudflareEnv)
}

unifiCreds = secret.ExternalSecret {
    name = "unifi-credentials"
    data = {
        UNIFI_HOST = {}
        UNIFI_USER = {}
        UNIFI_PASS = {}
    }
}

_unifiEnv = container.EnvMap {
    UNIFI_HOST = unifiCreds.getSecretKeyEnvRef("UNIFI_HOST")
    UNIFI_USER = unifiCreds.getSecretKeyEnvRef("UNIFI_USER")
    UNIFI_PASS = unifiCreds.getSecretKeyEnvRef("UNIFI_PASS")
    LOG_LEVEL = "debug"
}

unifiValues = _values | external_dns.Values {
    nameOverride = "unifi"
    provider.name = "webhook"
    provider.webhook = {
        image = {
            repository = "ghcr.io/kashalls/external-dns-unifi-webhook"
            tag = "main"
        }
        env = utils.EnvBuilder(_unifiEnv)
    }
}

app = frontend.App {
    name = "dns"
    tenantName = external.tenant.name
    secretStore = external.shared.secretStores.default.name
}
