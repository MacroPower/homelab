schema RenderContext:
    """Per-cluster render context, materialized once per `kcl run`.

    Every field defaults to the production hub's behavior, so a render with no
    `-D` options reproduces the live-cluster output unchanged. A non-prod cluster
    repoints these by passing `-D` once in its Argo CD config-management-plugin
    args (the plugin renders in-cluster and can only set process-global options
    per cluster, not per tenant or per app).

    Attributes
    ----------
    env: str.
        The cluster environment this render targets -- the value of the cluster
        Secret's `kubernetes.io/environment` label. The `tenants` ApplicationSet's
        cluster generator selects on it (so the tenant app-of-apps runs on this
        cluster), and it is the `destination.name` of the day-0 `bootstrap`
        Application. Defaults to the prod hub "mgmt".
    repoURL: str.
        Git repo the generated Applications/ApplicationSets source from.
    revision: str.
        Git revision the generated resources track.
    appEnvGlob: str.
        The env-dir segment the `{tenant}-apps` generator globs. "*" matches
        every environment (the hub has all spoke clusters registered); a single
        env name (e.g. "local") scopes generation to one cluster's overlays.
    fakeSecretStores: bool.
        When true, shared-tier ClusterSecretStores render with a `fake` provider
        instead of their real backend -- for offline clusters with no secret
        manager. Passed via `-D fake_secret_stores=`, parsed as a KCL bool, so it
        must be lowercase `true`/`false`; any other value fails the render.
    """
    env: str = "mgmt"
    repoURL: str = "https://github.com/MacroPower/homelab"
    revision: str = "main"
    appEnvGlob: str = "*"
    fakeSecretStores: bool = False

# Explicit defaults rather than truthiness-guards, so a field that ever defaults
# to a truthy value can still be overridden. Defaults match the schema above.
context: RenderContext = RenderContext {
    env = option("env", default="mgmt")
    repoURL = option("repo_url", default="https://github.com/MacroPower/homelab")
    revision = option("revision", default="main")
    appEnvGlob = option("app_env_glob", default="*")
    fakeSecretStores = option("fake_secret_stores", default=False)
}

__META_REPO_URL = context.repoURL
__META_REVISION = context.revision
