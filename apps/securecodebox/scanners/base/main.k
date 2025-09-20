import file

import konfig.models.frontend
import konfig.models.frontend.configmap
import konfig.files

import securecodebox
import charts.securecodebox_kube_hunter
import charts.securecodebox_nmap
import charts.securecodebox_generic_webhook
import charts.webhook

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "scanners"
    tenantName = securecodebox.tenant.name

    # https://github.com/secureCodeBox/secureCodeBox/tree/main/scanners/kube-hunter
    charts.securecodebox_kube_hunter = securecodebox_kube_hunter.Chart {
        values: securecodebox_kube_hunter.Values {}
    }

    # https://github.com/secureCodeBox/secureCodeBox/tree/main/scanners/nmap
    charts.securecodebox_nmap = securecodebox_nmap.Chart {
        values: securecodebox_nmap.Values {
            scanner: {
                env = [
                    {
                        name = "NMAP_PRIVILEGED"
                        value = "true"
                    }
                ]
                securityContext: {
                    runAsNonRoot = False
                    runAsUser = 0
                    capabilities = {
                        drop = ["ALL"]
                        add = [
                            "NET_RAW"
                            "NET_ADMIN"
                            "NET_BIND_SERVICE"
                        ]
                    }
                }
            }
        }
    }

    # https://github.com/secureCodeBox/secureCodeBox/tree/main/hooks/generic-webhook
    # https://grafana.com/docs/grafana-cloud/alerting-and-irm/irm/configure/integrations/webhooks/incoming-webhooks/incident-webhooks/
    charts.securecodebox_grafana_webhook = securecodebox_generic_webhook.Chart {
        values: securecodebox_generic_webhook.Values {
            webhookUrl = "http://webhook/hooks/stdout"
        }
    }

    charts.webhook = webhook.Chart {
        values: _values | webhook.Values {}
    }

    configMaps.webhook = configmap.ConfigMap {
        name = "webhook-config"
        data: {
            "hooks.yaml" = files.read_file(file.current(), "config/hooks.yaml")
            "stdout.sh" = files.read_file(file.current(), "config/stdout.sh")
        }
    }
}
