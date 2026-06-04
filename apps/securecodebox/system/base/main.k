import file

import konfig.models.frontend
import konfig.models.frontend.secret
import konfig.files
import helm

import securecodebox_shared
import charts.securecodebox

_values = files.read_yaml(file.current(), "values.yaml")

_s3Config = secret.ExternalSecret {
    name = "s3-config"
    data: {
        S3_ACCESS_KEY = {
            remoteRef.key = "SECURECODEBOX_S3_ACCESS_KEY"
        }
        S3_SECRET_KEY = {
            remoteRef.key = "SECURECODEBOX_S3_SECRET_KEY"
        }
    }
}

app = frontend.App {
    name = "system"
    tenantName = securecodebox_shared.tenant.name
    secretStore = securecodebox_shared.shared.secretStores.default.name

    externalSecrets.s3Config = _s3Config

    charts.securecodebox = securecodebox.Chart {
        values: _values | securecodebox.Values {}
        postRenderer = lambda resource: helm.Resource -> helm.Resource {
            if resource.kind == "Deployment" and resource.metadata.name == "securecodebox-controller-manager":
                resource.spec.template.spec.containers[0].env = [
                    {
                        name = env.name
                        if not isnullish(env.value):
                            value = str(env.value)
                        else:
                            valueFrom = env.valueFrom
                    }
                    for env in resource.spec.template.spec.containers[0].env
                ]
            resource
        }
    }
}
