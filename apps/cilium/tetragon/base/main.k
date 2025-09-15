import file

import konfig.models.frontend
import konfig.models.utils as modelutils
import konfig.files

import cilium
import charts.tetragon
import charts.tetragon.api.v1alpha1 as tetrav1alpha1

_values = files.read_yaml(file.current(), "values.yaml")

app = frontend.App {
    name = "tetragon"
    tenantName = cilium.tenant.name

    charts.tetragon = tetragon.Chart {
        values: _values | tetragon.Values {}
    }

    # This 'creds-capability-usage' Tracing Policy monitors capability checks
    # performed by the kernel when a process tries a privileged operation. This
    # Tracing Policy works inside a pid namespace, if you want to monitor all
    # processes including host ones, remove the matchNamespaces selector.
    extraResources.credsCapabilityChecks = tetrav1alpha1.TracingPolicy {
        metadata: modelutils.AppMetadataBuilder(
            { name = "creds-capability-checks" },
            modelutils.ArgoCDOptions {
                sync.SkipDryRunOnMissingResource = True
            }
        )
        spec: {
            kprobes = [{
                "call" = "cap_capable"
                "syscall" = False
                "return" = True
                "args" = [
                    {
                        "index" = 1
                        "type" = "user_namespace"
                    }
                    {
                        "index" = 2
                        "type" = "capability"
                    }
                ]
                "returnArg" = {
                    "index" = 0
                    "type" = "int"
                }
                "selectors" = [{
                    "matchNamespaces" = [{
                        "namespace" = "Pid"
                        "operator" = "NotIn"
                        "values" = ["host_ns"]
                    }]
                    "matchActions" = [{
                        "action" = "Post"
                        "rateLimit" = "1m" # Rate limit messages to 1min
                    }]
                }]
            }]
        }
    }
}
