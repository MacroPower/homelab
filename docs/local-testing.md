# Local testing with Talos-in-Docker + Argo CD

A throwaway, single-node Kubernetes cluster that runs the real GitOps stack
against your **working tree**, so you can sync and debug app changes locally
before they ever reach GitHub. It is made as close to the real clusters as
nested Docker allows: Talos with `cni=none`, the real Cilium datapath with
kube-proxy replaced, and the stock Argo CD rendering KCL through the kclipper
config-management plugin.

Everything lives under `.taskfiles/talos-docker/` and is driven by `task tald:*`.

## Prerequisites

- The **rootful** Docker daemon, reachable via `sudo` (Talos-in-Docker writes
  host sysctls and `/dev/kmsg`, which rootless Docker forbids even when
  privileged). The harness inlines `DOCKER_HOST=unix:///run/docker.sock` and
  wraps Docker/talosctl calls in `sudo -E`.
- The devshell tools: `talosctl`, `talhelper`, `kubectl`, `yq`, and `kcl`
  (kclipper). Enter it with
  `nix develop` / `direnv`, which also exports the vendored KCL paths
  (`KCL_LIB_HOME`, `KCL_PKG_PATH`, `KCL_CACHE_PATH` under `.nix/kcl`).
- Outbound network access. The harness pulls container images and Helm charts
  from public registries (ghcr.io, quay.io, registry.k8s.io, docker.io) at run
  time; only secrets, DNS, storage, and load balancers are stubbed.

All state (kubeconfig, plus the generated machine config and talosconfig under
`.cache/clusterconfig`) is written under the git-ignored `.cache/` directory, so
the test cluster never touches your real
`~/.kube/config` or homelab contexts. The `tald:*` tasks always pass an explicit
`--kubeconfig`/`--talosconfig` under `.cache`, so they target the test cluster
regardless of (and without disturbing) any `KUBECONFIG` exported in your shell.
To point your *own* `kubectl` at it:

```sh
export KUBECONFIG="$(git rev-parse --show-toplevel)/.cache/kubeconfig"
# or: task tald:kubeconfig
```

For zero-ceremony access, `tald:up` also merges the cluster into the standard
`~/.kube/config` (additively, via `kubectl config view --flatten`; `tald:down`
removes it again) under context `admin@local`, so any shell reaches it with no
env var and no flag:

```sh
kubectl config use-context admin@local
```

Re-run `task tald:kubectx` by hand if the cluster outlives the shell that
registered it. The harness's own commands always pass an explicit `--kubeconfig`
under `.cache`, so they target the test cluster regardless of which context is
current.

## Quickstart

```sh
task tald:all       # cluster + Cilium + git mirror + Argo CD + stubs (~5-8 min cold)
task tald:status    # cluster nodes + Argo CD application health
task tald:ui        # port-forward the (auth-disabled) Argo CD UI to localhost:8080
task tald:logs      # follow the Argo CD controller + repo-server logs

# inner loop: edit any apps/*/*/local overlay (or its base), then:
task tald:push      # snapshot the working tree to the mirror + refresh Argo CD
task tald:status    # watch it reconcile
task tald:diff APP=kube-reloader-local   # what a sync would change (argocd CLI)
task tald:sync                           # force a reconcile via the argocd CLI

task tald:down      # destroy the cluster and clean local state
```

`task tald:all` is idempotent at the cluster level: if the controlplane
container is already running, `tald:up` is a no-op and the later steps reconcile.

## The inner loop

The cluster reconciles a git **mirror** of your working tree, not GitHub. Each
`task tald:push` snapshots the entire working tree -- including uncommitted edits
and new files, honoring `.gitignore` -- into a private `refs/tald/local` ref
using a throwaway index, pushes that to the in-cluster mirror's `local` branch,
and asks Argo CD to hard-refresh. Your real branch, index, and working tree are
never touched, the private ref namespace never collides with a real branch, and
nothing lands in your history.

So the loop is: **edit KCL -> `task tald:push` -> `task tald:status`**. Validate
locally first with `task tald:render`, which compiles every `apps/*/*/local`
overlay plus `bootstrap/core/local`, the prod hub day-0 bundle
(`bootstrap/core/mgmt`), the git mirror (`bootstrap/hack`), and the `appsets/`
package offline and fails fast.

## Driving Argo CD with the argo CLI

The same `argocd` CLI the live clusters are driven with (the `argocd:*` tasks)
also works against the test cluster, over an **ephemeral port-forward** to the
in-cluster Argo CD server -- the same `--port-forward` transport the live
`argocd:*` tasks use, so the local inner loop and a real cluster drive Argo
through one mechanism:

- `task tald:diff APP=<tenant>-<app>-local` -- show what a sync would change.
- `task tald:sync [APP=<tenant>-<app>-local]` -- force a reconcile (every app if
  `APP` is omitted), the day-2 counterpart to `tald:push`'s working-tree snapshot.
- `task tald:argo -- <args>` -- run any argocd subcommand, e.g.
  `task tald:argo -- app list` or `task tald:argo -- app logs kube-reloader-local`.

These need the `argocd` binary; the bring-up itself does not -- it drives Argo
through kubectl, so a cold cluster comes up without it. The tasks port-forward to
the `argo-cd-server` pod in the `argo-cd` namespace and connect `--plaintext`;
the local overlay disables auth (`server.insecure` + `disable.auth`), so no login
is needed. `argocd --core` is deliberately avoided: its in-process API server is
unreliable under the harness's nested Docker, and it would have to mutate the
repo-local kubeconfig (a write that can wedge a stale lockfile on the
`.cache` mount).

## How it works

The flow mirrors the real bootstrap, with three substitutions (CNI/datapath
relaxations, an in-cluster git mirror, and a per-cluster render context that
repoints in-cluster renders at the mirror and scopes the tenant hierarchy to
this cluster). The day-0 render and apply are literally the shared
`kcl:bootstrap-render` and `kcl:apply-retry` tasks the live clusters use (tald
passes the mirror `-D` and a hermetic `kubectl --kubeconfig`); every `kcl run`
across tald, the live bootstrap, and the render gate carries the same
`KCL_RUN_FLAGS` (the manifest-affecting flags of the in-cluster CMP), so a clean
local render predicts a clean in-cluster one. It is expressed entirely as native
Task tasks -- no shell scripts; each step below is a `tald:*` task chaining small
internal tasks:

1. **Cluster (`tald:up`).** The node's machine config is generated by **talhelper**
   in container mode from `clusters/local/talconfig.yaml`, the same tool the live
   clusters use. That talconfig includes the shared container-safe fragments in
   `clusters/base/` (`machine.common.yaml` and `cluster.common.yaml`:
   `proxy.disabled`, the control-plane feature gates / cipher suites, `hostDNS`,
   PodSecurity, and the `kubelet.extraMounts` rbind for `/var/openebs/local`), the
   same files `clusters/main` and `clusters/mgmt` consume, while omitting the
   bare-metal `*.metal.yaml` fragments. The container/single-node deltas live in
   `clusters/local/machine.yaml` (`forwardKubeDNSToHost: true`, KubePrism) and
   `clusters/local/cluster.yaml` (`allowSchedulingOnControlPlanes: true`). Its
   pinned `talosVersion` / `kubernetesVersion` are asserted equal to
   `clusters/<TALD_TALOS_REF>/talconfig.yaml` (default `main`), so the node tracks
   the same versions a real cluster runs rather than talosctl's drifting defaults.

   `talosctl cluster create docker` (v1.12) cannot consume a pre-generated config,
   so the `node-up` task runs the Talos image directly: it creates the bridge
   network and a `docker run` of `ghcr.io/siderolabs/talos`, replicating the docker
   provisioner's container spec and injecting the generated `controlplane.yaml` as
   base64 `USERDATA` (how the Talos container platform reads its config).
   `wait-apiserver` then waits for the node API, issues `talosctl bootstrap`, pulls
   a kubeconfig, and the `cilium` task brings the datapath up. The result is a
   pristine `cni=none`, kube-proxy-less node.

2. **Cilium (`tald:cilium`).** Renders `apps/cilium/system/local`,
   a Docker-safe overlay of the real Cilium config: `veth` instead of `netkit`,
   iptables masquerade instead of BPF, no host firewall / bandwidth manager /
   IPv6 / BGP / LoadBalancer-IPAM, single operator replica. It keeps
   `kubeProxyReplacement`, the KubePrism endpoint (`localhost:7445`), and
   tunnel/VXLAN routing, so the datapath is the real one.

3. **Git mirror (`tald:git`).** A `hostNetwork` pod
   (rendered from `bootstrap/hack/git-mirror`) serving the working-tree
   snapshot over `git://<node>:9418/homelab.git`. It runs on hostNetwork because Cilium
   excludes the node's own docker subnet from masquerade, so pods cannot reach a
   server on the docker bridge gateway -- but they reach the node IP just like
   the apiserver, and the host reaches it too over the bridge.

4. **Bootstrap (`tald:bootstrap`).** Renders `bootstrap/core/local` via the
   shared `kcl:bootstrap-render` and applies it via `kcl:apply-retry` (which
   retries the server-side apply while the Argo CRDs in the bundle establish):
   the stock (insecure, auth-disabled)
   Argo CD (the `apps/argo/cd/local` overlay, whose CMP injects this cluster's
   render context), the kubelet CSR approver, the `local` cluster Secret, and a
   `bootstrap` Application -- the SAME shared `argocd.bootstrapApp`
   (`konfig/argocd/bootstrap.k`) the mgmt hub uses, pointed at the mirror with
   `env=local`. Argo CD syncs that Application to render the `appsets/` package
   in-cluster (through the CMP, which injects `env=local`) into this cluster's
   `tenants` ApplicationSet -- the shared `tenantsAppSet` builder
   (`konfig/argocd/tenants.k`). Each tenant Application that appset
   generates renders `TenantBackend` in-cluster, producing the per-tenant
   AppProjects and `{tenant}-apps` / `{tenant}-shared` ApplicationSets, exactly
   as on the mgmt hub. Local and the hub bootstrap the tenant hierarchy through
   one identical path: `bootstrap` Application -> `appsets/` -> `tenants` appset.

   The render context (`RenderContext` in
   `konfig/models/metadata/metadata.k`) carries `env`, `repoURL`, `revision`,
   `appEnvGlob`, and `fakeSecretStores`, each defaulting to the prod-hub value --
   so a `kcl run` with no `-D` is byte-for-byte the production output. The
   bootstrap render takes `env`/`repoURL`/`revision` as `-D`, and the argo-cd
   overlay bakes `env`, the mirror seam, the env glob, and the fake-store flag
   into the CMP's `kcl run` args, so **in-cluster** renders (the bootstrap
   Application's `appsets/`, then tenant bases, then apps) resolve the mirror and
   the `local` env, scope `{tenant}-apps` to `*/local`, and render offline-safe
   secret stores -- **no edits to the prod-synced tree's rendered output**.

Beyond the day-0 bootstrap layer (Cilium, Argo CD, the CSR approver -- applied
imperatively by `tald:bootstrap` and not re-adopted as Argo apps), there is no
imperative seed step. Every app-tier cluster
dependency that the real clusters get from an app rides a `local/` overlay, and
Argo CD applies it -- retrying until prerequisites (CRDs, namespaces) are
established -- exactly as prod does:

- **Storage.** `apps/kube/openebs/local` runs a minimal OpenEBS: every engine
  off (no disks, ZFS pool, or hugepages on a dockerized node), just the
  umbrella chart's unconditional localpv-provisioner. It marks that subchart's
  `openebs-hostpath` class -- backed by a host directory under Talos' writable
  `/var` -- the cluster default, so PVCs with no `storageClassName` bind. Prod's
  owner is `apps/kube/openebs`.
- **Secrets.** The shared-tier `ClusterSecretStore`s (the `external` store and
  the rest) render with a `fake` provider because the render context sets
  `fakeSecretStores=true`, so dependent `ExternalSecret`s resolve offline with no
  Doppler backend -- no hand-written stub.
- **Prometheus operator CRDs.** Carried by `apps/o11y/k8s-monitoring/local`, via
  the pinned `prometheus-operator-crds` chart it inherits from base, so
  ServiceMonitor/PodMonitor resources apply.

This is the same rule prod follows for CRD-then-CR ordering: a CR lives in the
same app that installs its operator -- cert-manager `ClusterIssuer`s in
`apps/external/certs`, external-secrets CRs in `apps/external/secrets` -- and is
never stubbed out of band.

Two pieces are local-only. `bootstrap/hack/git-mirror` is the working-tree
server, applied directly because it is what *serves* the repo to Argo CD and so
cannot itself be an Argo app -- it lives under `bootstrap/hack` rather than
`bootstrap/core/local` precisely because it is harness plumbing, not part of the
local cluster's bootstrap. `apps/argo/cd/local` is the cluster's Argo CD overlay
(parallel to `apps/argo/cd/mgmt`); beyond the stock base it bakes this cluster's
render context into the CMP `kcl run` args and registers the `homelab` repository
pointing at the git mirror. The base and the prod hub overlay register no
repository at all -- prod reaches the public GitHub repo anonymously -- but
repo-server's `/healthz?full=true` readiness probe lists refs for every registered
repository, so the local overlay defines the `homelab` repo as the anonymous
`git://` mirror Argo can reach offline with no secret (no SSH deploy key exists or
is needed). The node's Talos config is talhelper's domain, not Kubernetes':
`clusters/local/talconfig.yaml` (plus the shared `clusters/base/machine.common.yaml`
and `cluster.common.yaml` fragments it includes) is rendered to a machine config
and injected into the Talos container as `USERDATA`.

## The tenant hierarchy

Local deploys the **real** prod tenant hierarchy, not a substitute. The local
`tenants` ApplicationSet is the **same** shared `konfig.argocd.tenantsAppSet(env,
ctx)` builder (`konfig/argocd/tenants.k`) that prod uses -- instantiated with
`env=local` and the mirror render context instead of `env=mgmt` and the GitHub
context. Its cluster generator selects `kubernetes.io/environment=local` and its
source is the mirror. It generates one Application per tenant base
(`apps/*/_tenant/base/.tenant.yaml`); each renders `TenantBackend` in-cluster,
emitting that tenant's `{tenant}-apps` and `{tenant}-shared` AppProjects and
ApplicationSets -- the same two-level app-of-apps the mgmt hub runs.

That top-level appset is **shared, not copied**. Both clusters render it from the
one `appsets/` package (`appsets/main.k`, which calls `tenantsAppSet(ctx.env,
ctx)`) via their day-0 `bootstrap` Application: the prod hub with the default
context (`env=mgmt`, GitHub) and the local harness with `env=local` and the
mirror context. The env selector and the mirror repoURL/revision are *arguments*
supplied via the render context's `-D` flags, so the package has no
environment-specific copy. Everything *below* the top-level appset (the
`{tenant}-apps` / `{tenant}-shared` tiers) is the unmodified `TenantBackend`,
also shared with prod.

The single knob that makes this fit one cluster is the render context's
`appEnvGlob`. `TenantBackend`'s `{tenant}-apps` generator globs
`apps/{tenant}/*/${appEnvGlob}/.app.yaml`; on the hub `appEnvGlob` defaults to
`*` (every environment, because every spoke cluster is registered), and the
local CMP sets it to `local`, so the generator matches only `local/` overlays and
its `destination.name` (the env-dir basename) resolves to the one registered
`local` cluster. So an app is in the local set exactly when it has a `local/`
overlay, and it runs under the same scoped `{tenant}-apps` project, the same
`{tenant}-{app}-local` naming, and the same `tenant`/`app` labels as prod -- all
produced by the unmodified `TenantBackend`, not re-implemented in the harness.

The `{tenant}-shared` tier runs too: it renders each tenant's `SharedApp`, whose
`ClusterSecretStore` becomes a `fake` provider via `fakeSecretStores`. The cost
is faithfulness -- the local cluster carries the same project/appset/store
topology a real cluster does (one `tenants` appset, 14 `{tenant}-apps` + 14
`{tenant}-shared` appsets, 28 scoped projects), with tenants that have no `local/`
overlay contributing only an inert project and a fake store.

## Adding an app to the local set

Add a `local/` overlay next to the app's `base/` and `mgmt/`. Use
`apps/kube/reloader/local/` as the template -- four files:

- `kcl.mod` -- package `<tenant>_<app>_local`, a path dependency on `../base`,
  and `[profile] entries = ["main.k", "${konfig:KCL_MOD}/models/render/render.k"]`.
- `main.k` -- mirror the app's own `mgmt/main.k`: import the base, `json_merge_patch`
  a local `values.yaml` over the base chart values, return `app = <base>.app | {...}`.
- `values.yaml` -- only the Docker-safe overrides (see below).
- `.app.yaml` -- per-app sync config read by the `{tenant}-apps` ApplicationSet's
  git-file generator and applied through its `templatePatch`
  (`syncPolicy.automated`, optional `ignoreDifferences`). That `{tenant}-apps`
  appset is the unmodified shared `TenantBackend`, identical on local and prod,
  so `.app.yaml` is consumed exactly as in prod. Copy reloader's verbatim for the
  usual `automated.selfHeal: true`.

Docker-safe overrides to apply in the local `values.yaml`:

- Drop multi-replica HA / PodDisruptionBudgets that would strand a pod on one node.
- Change `type: LoadBalancer` Services to `ClusterIP`; drop BGP and
  `CiliumLoadBalancerIPPool` resources. Reach services with `kubectl port-forward`.
- Override unavailable StorageClasses (openebs-zfs, rook, ...) to `openebs-hostpath`,
  or drop `storageClassName` entirely so the PVC takes the default class.
- Keep ServiceMonitor/PodMonitor (`apps/o11y/k8s-monitoring/local` carries the
  CRDs) and the
  CiliumNetworkPolicies (they use the `kube-apiserver`/`kube-dns` entities, which
  resolve locally).

Then `task tald:render` to compile it, `task tald:push` to deploy it, and
`task tald:status` to watch it reconcile.

## Known limits and differences from prod

- **Secrets.** The shared-tier `ClusterSecretStore`s render with a `fake`
  provider (the `fakeSecretStores` render context) answering only `dummy`
  (`ClusterSecretStoreMixin` in `konfig/models/mixins/secret_mixin.k`). Apps whose
  `ExternalSecret`s read other keys stay degraded; truly secret-dependent apps are
  out of scope for the offline cluster.
- **LoadBalancers / DNS / ingress.** No external IPs and no real DNS. Services of
  type LoadBalancer stay pending; reach things via port-forward. Treat
  "LB IP assigned" as out of scope, not as success.
- **Storage.** `openebs-hostpath` only (RWO hostpath, the default class served by
  `apps/kube/openebs/local`). No `ReadWriteMany`, no ZFS / Ceph / object storage.
- **Single node.** No anti-affinity spread, no multi-node failure testing. The
  control plane is schedulable and runs everything.
- **Images pulled live.** First bring-up is slow while images and charts download
  (e.g. the Cilium operator image is ~60 MB from quay.io); subsequent runs reuse
  the node's containerd cache and the KCL chart cache.

## Troubleshooting

- **`task tald:up` fails a precondition.** `up` requires `talosctl`, `talhelper`,
  `kcl`, `kubectl`, and `yq` on `PATH` -- enter the devshell (`nix
  develop`/`direnv`). A missing or unreachable rootful Docker daemon is not caught
  by a precondition; it surfaces as the `docker run` failing or the node never
  answering, and `tald:up` times out in `wait-apiserver`. Inspect the node's boot
  log with `sudo docker logs homelab-local-controlplane-1` (the `wait-apiserver`
  and `bootstrap-node` steps tail it on timeout).
- **No Applications generated right after bootstrap.** The
  applicationset-controller's first gRPC dial to the repo-server can race
  Cilium's socket-LB programming for the fresh Argo pods and stick on
  "connect: operation not permitted". The `kick-appset` task (run by
  `tald:bootstrap`) restarts the controller in a loop until Applications appear;
  if you ever see it stuck, clear it by hand with `task tald:appset-restart` (or
  `kubectl -n argo-cd rollout restart deploy/argo-cd-applicationset-controller`).
- **An app renders but will not go Healthy.** Inspect it with
  `task tald:debug APP=<tenant>-<app>-local` (status, conditions, and the
  workload's pods/events), and follow the controllers with `task tald:logs`. Most
  failures are a missing CRD (carry it in the owning app's `local/` overlay), a
  missing secret key, or a LoadBalancer/storage assumption -- see the limits above.
- **Apps point at GitHub or the wrong env, or Applications target a `mgmt`/`main`
  cluster.** The CMP did not inject the render context. Check that the local
  Argo CD shipped the overlay's `-D` flags:
  `kubectl -n argo-cd get cm argocd-cmp-cm -o yaml | grep -E 'repo_url|app_env_glob|fake_secret_stores'`.
  They are baked at install time, so a repo-server already running with the stock
  config will not pick them up -- rebuild (`task tald:down && task tald:all`)
  rather than re-applying onto a live cluster.
- **Start over.** `task tald:down && task tald:all`.
