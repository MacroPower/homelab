import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.models.frontend.configmap
import konfig.files

import o11y
import charts.wakatime_exporter
import charts.readme_updater

_values = files.read_yaml(file.current(), "values.yaml")

_wakatimeCreds = secret.ExternalSecret {
    name = "wakatime-credentials"
    data: {
        WAKATIME_API_KEY = {}
    }
}

app = frontend.App {
    name = "wakatime-exporter"
    tenantName = o11y.tenant.name
    secretStore = o11y.shared.secretStores.default.name

    externalSecrets: {
        wakatimeCreds = _wakatimeCreds
    }

    charts.wakatime_exporter = wakatime_exporter.Chart {
        values: _values | wakatime_exporter.Values {
            env: {
                WAKA_API_KEY = {
                    valueFrom = _wakatimeCreds.getSecretKeyEnvRef("WAKATIME_API_KEY")
                }
            }
        }
    }

    configMaps.readmeConfig = configmap.ConfigMap {
        name = "readme-config"
        data: {
            "update-graph.sh" = files.read_file(file.current(), "config/update-graph.sh")
        }
    }

    externalSecrets.readmeRepo = secret.ExternalSecret {
        name = "readme-repo"
        data: {
            WAKATIME_GITHUB_REPO_URL = {}
        }
    }

    # TODO: Replace all of this.
    charts.readme_updater = readme_updater.Chart {
        values: readme_updater.Values {
            global: {
                fullnameOverride = "readme-updater"
                nameOverride = "readme-updater"
            }
            controllers.app = {
                type = "cronjob"
                cronjob: {
                    schedule = "0 * * * *"
                    successfulJobsHistory = 1
                    failedJobsHistory = 3
                    concurrencyPolicy = "Forbid"
                    suspend = True
                }
                containers.app = {
                    image: {
                        repository = "golang"
                        tag = "1.21"
                    }
                    command = "/bin/bash"
                    args = "/app/config/update-graph.sh"
                    env: {
                        WAKATIME_GITHUB_REPO_URL = {
                            valueFrom = externalSecrets.readmeRepo.getSecretKeyEnvRef("WAKATIME_GITHUB_REPO_URL")
                        }
                    }
                }
            }
            persistence: {
                config: {
                    type = "configMap"
                    name = configMaps.readmeConfig.name
                    defaultMode = 0o755
                    globalMounts = [{
                        path = "/app/config/update-graph.sh"
                        subPath = "update-graph.sh"
                        readOnly = True
                    }]
                }
                repos: {
                    type = "persistentVolumeClaim"
                    size = "5Gi"
                    accessMode = "ReadWriteOnce"
                    storageClass = "openebs-hostpath"
                    globalMounts = [{
                        path = "/app/repos"
                    }]
                }
            }
        }
    }
}
