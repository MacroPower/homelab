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

# Merge over the base argocd-cmd-params, preserving its keys (dotted param names
# are string keys, so this must be an explicit dict union rather than an
# attribute-path assignment).
_params = argo_cd_base.app.charts.argo_cd.values.configs.params

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

    # After three consecutive failed manifest generations the repo-server stops
    # retrying an app and replays the cached error for ARGOCD_PAUSE_GEN_MINUTES
    # (default 60). On this cluster the failures it pauses on are transient -- a
    # heavy chart still downloading on a cold cache, or contention during a
    # bring-up render storm -- so a 60-minute pause turns a momentary miss into an
    # app that sits broken until someone hard-refreshes it. Drop the pause to a
    # minute so a transient failure self-heals on the next reconcile once the
    # chart cache warms, instead of needing a manual nudge. Prod's renders do not
    # download charts at request time, so its failures are real and it keeps the
    # protective 60-minute pause.
    charts.argo_cd.values.repoServer.env = [
        {
            name = "ARGOCD_PAUSE_GEN_MINUTES"
            value = "1"
        }
    ]

    # Persist the kclipper sidecar's KCL package + Helm chart cache across cluster
    # rebuilds, the root of the cold-cache pain the two knobs above only soften.
    # Base mounts the sidecar only ephemeral volumes, so every fresh node renders
    # against a cold cache and the first render of each app re-downloads its KCL
    # deps and charts -- the slowest part of a bring-up. Point the KCL cache env at
    # a mounted dir (the same kpm/cache/lib split the host devshell uses) backed by
    # a hostPath on /var/kcl-cache: a named Docker volume the harness mounts into
    # the node and chowns to the sidecar's uid 999 (see tald:kcl-cache-up), which
    # outlives tald:down. The sidecar is augmented in place rather than restated,
    # so a base image or arg bump still flows through. Local-only -- prod's
    # repo-server renders against an already-warm cache.
    charts.argo_cd.values.repoServer.extraContainers = [
        c | {
            volumeMounts = c.volumeMounts + [{
                name = "kcl-cache"
                mountPath = "/home/argocd/.cache/kcl"
            }]
            env = (c.env or []) + [
                {name = "KCL_PKG_PATH", value = "/home/argocd/.cache/kcl/kpm"}
                {name = "KCL_CACHE_PATH", value = "/home/argocd/.cache/kcl/cache"}
                {name = "KCL_LIB_HOME", value = "/home/argocd/.cache/kcl/lib"}
            ]
        } if c.name == "kcl-plugin" else c
        for c in argo_cd_base.app.charts.argo_cd.values.repoServer.extraContainers
    ]

    charts.argo_cd.values.repoServer.volumes = argo_cd_base.app.charts.argo_cd.values.repoServer.volumes + [{
        name = "kcl-cache"
        hostPath = {
            path = "/var/kcl-cache"
            type = "DirectoryOrCreate"
        }
    }]

    # Same cold-cache cause, upstream of the pause. A bring-up -- or a repo-server
    # roll that empties the manifest cache -- makes the controller ask for every
    # app's manifest at once, and a heavy chart's first render has to download the
    # chart before it can compile. Under that contention the slow ones can exceed
    # the default 60s controller -> repo-server deadline and get cut off, and a cut
    # render counts as a failed generation (three of those trip the pause above).
    # Widen the deadline, on both the controller and the CLI-driven server path,
    # so the first cold render finishes instead of being killed. Parallelism is
    # left unbounded on purpose: the node has cores and memory to spare, so the
    # herd clears fastest rendering at once, whereas a low limit just queues the
    # heavy renders until they time out. Prod renders against a warm chart cache
    # and never hits this, so it keeps the tight chart defaults.
    charts.argo_cd.values.configs.params = _params | {
        "controller.repo.server.timeout.seconds" = 180
        "server.repo.server.timeout.seconds" = 180
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
