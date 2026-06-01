import konfig.models.metadata as kmd

import argo_cd_base

# Inject the local render context as `-D` flags appended to the base CMP command,
# so every in-cluster render on this cluster resolves the mirror and the `local`
# env scope. In particular the `bootstrap` Application's `appsets/` render picks
# up `env=local`, so the `tenants` ApplicationSet it emits targets this cluster.
#
# Must APPEND to the base CMP args (a KCL list concat), not json_merge_patch a
# values.yaml over them like the app overlays do: json_merge_patch (RFC 7396)
# replaces arrays wholesale, which would drop the base `run --no_style ...`
# invocation and break the plugin.
_generate = argo_cd_base.app.charts.argo_cd.values.configs.cmp.plugins.kcl.generate

# Register the anonymous git:// mirror as the `homelab` repo. repo-server's
# `/healthz?full=true` liveness probe lists refs for every registered repository,
# so this entry must point at a repo Argo can reach offline; prod registers none
# and reaches GitHub anonymously.
app = argo_cd_base.app | {
    charts.argo_cd.values.configs.repositories.homelab.url = kmd.context.repoURL

    # The single dockerized node runs the whole stack on shared CPU. A push
    # refreshes every app at once, and the repo-server -- plus its in-process KCL
    # CMP compiling each manifest -- saturates the node, stalling even the trivial
    # `/healthz` handler past the chart's 1s probe timeout (the `full=true`
    # liveness check additionally `ls-remote`s the mirror behind the per-repo
    # lock). At the chart defaults a missed liveness probe restarts the pod
    # mid-render, and a missed readiness probe drops it from the Service; either
    # one strands in-flight comparisons and cascades apps into ComparisonError.
    # Widen both timeouts so the probes ride out a render storm while still
    # tripping on a genuinely wedged process. Prod keeps the tight chart defaults.
    charts.argo_cd.values.repoServer.livenessProbe = {
        timeoutSeconds = 30
        failureThreshold = 5
    }
    charts.argo_cd.values.repoServer.readinessProbe = {
        timeoutSeconds = 30
        failureThreshold = 5
    }

    charts.argo_cd.values.configs.cmp.plugins.kcl.generate.args = (_generate?.args or []) + [
        "-D"
        "env=local"
        "-D"
        "repo_url=${kmd.context.repoURL}"
        "-D"
        "revision=${kmd.context.revision}"
        "-D"
        "app_env_glob=local"
        "-D"
        "fake_secret_stores=true"
    ]
}
