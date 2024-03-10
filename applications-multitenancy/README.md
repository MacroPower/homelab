# Argo CD Multitenancy Example

This is an example of how to use Argo CD to manage multiple tenants in a cluster.

```
┌───────────────────────────────────────────────────────┐
│                     Managed Repo                      │
├───────────────────────────────────────────────────────┤
│  ┌───────────────┐                                    │
│  │  Application  │                                    │
│  └───────────────┘                                    │
│    │                                                  │
│    ├───────────────────┐                              │
│    │                   │                              │
│    ▼                   ▼                              │
│  ┌────────────────┐  ┌────────────────┐               │
│  │ ApplicationSet │  │ ApplicationSet │               │
│  └────────────────┘  └────────────────┘               │
│    │                   │                              │
│    │   ┌───────────┐   │   ┌─────────────┐            │
│    ├──▶│  Project  │   ├──▶│ Application │            │
│    │   └───────────┘   │   └─────────────┘            │
│    │                   │          │                   │   ┌───────────────────────┐
│    │                   │          │   ┌────────────┐  │   │       App Repo        │
│    │                   │          ├──▶│ Namespace  │  │   ├───────────────────────┤
│    │                   │          │   └────────────┘  │   │                       │
│    │                   │          │   ┌ ─ ─ ─ ─ ─ ─   │   │    ┌─────────────┐    │
│    │                   │          └──▶  Parameters │──┼───┼───▶│ Application │    │
│    │                   │              └ ─ ─ ─ ─ ─ ─   │   │    └─────────────┘    │
│    │                   │                              │   │                       │
│    │   ┌───────────┐   │   ┌─────────────┐            │   └───────────────────────┘
│    └──▶│  Project  │   └──▶│ Application │            │
│        └───────────┘       └─────────────┘            │
│                                                       │
└───────────────────────────────────────────────────────┘
```

Features of this approach / design constraints:

- Local development is possible on all tenant applications.
  - E.g. diff, dry-run, and sync from local sources.
- Keeps support for Argo CD's history, rollback, restart, etc. via the Argo CD UI, with per-tenant restrictions.
- Application code can be (almost) entirely consolidated in a single repository.
  - With the exception of the cluster state, i.e. which revision of the application is deployed to a given cluster.
- Application code can contain pre-sync configuration that is applied before the app is synced.
  - Automatically attach owership/cost-center metadata without needing to supply it via the application chart.
  - Modify select policy behavior, e.g. enable PDB auto-creation, configure firewalls, etc.
- Clusters can be bootstrapped from nothing with a single command.
  - This can be quite helpful for DR, migration, and/or multi-region deployments.
  - It's possible also to command large sets of applications, e.g. all applications in a given business unit.
- Supports defining sync order between projects, and applications/resources in a project.
- No custom config management plugins required.
  - A few edits to argocd-cm.yaml & argocd-cmd-params-cm.yaml may be needed.

Why other approaches I've seen do not work well:

- They use multiple sources on end-user applications, which disables local development features, as well as a number of features in the Argo CD UI.
- They do not utilize "Applications in any namespace", in favor of creating all Applications in a control plane namespace, which again removes some local development features (e.g. ability to suspend/resume self-healing), and takes away self-servicability from app teams.
- They use Kustomize with the helmCharts option, which means you cannot pull OCI artifacts.
- They either entirely segregate application code and kubernetes manifests, or bundle everything together. While this does avoid a number of challenges (e.g. access control), my opinion is that neither of these approaches typically fit all use cases, and frequently result in shoehorning which either significantly impedes cycle times, or hurts security/isolation.

## Repo Layout

The "managed" folder could be a monorepo, or repos could be created per team, or some combination of these approaches could be followed. It is important that access remains somewhat guarded, to prevent tenants from unintentionally or maliciously impacting other tenants, e.g. by taking over their namespace. Likely the best approach is to almost entirely manage this repo with automation, e.g. argocd-image-updater, and use said automation to enforce RBAC.

The "charts" folder also could be its own repo, with said charts published to a chart repository, or it could exist in the "managed" repo if that is a monorepo.

Each folder under "examples" would be its own repo containing the included manifests as well as the application code.

## Naming

It might be a good idea to automatically prefix namespaces by the name of their team, thus avoiding any potential namespace collisions which become possible under the <team>/<app> folder structure. You might be tempted to just put all namespaces into a single folder to do this naturally, but note that this will prevent you from being able to shard the management repositories without adopting multiple naming conventions.

## Cons with this approach

This approach will require a somewhat experienced platform team to properly implement. I would not recommend pushing a platform team into this approach unless they have a solid understanding of Kubernetes, Argo CD, and whatever policy engine you are using.

- There are more Argo CD Applications to manage; each tenant Application requires a parent Application on the back-end, managed by an ApplicationSet. This is in contrast to some approaches where Applications are simply created via the UI, or applied via a Terraform module.
- Since there are several sources pulled by each application, there will be more load on the Argo CD server, as well as more pulls from git. So, you may need to scale your Argo CD server and/or configure caching/rate-limits/etc on the argocd-repo-server. If you set up CD pipelines to trigger syncs, this should be less of an issue.
- You must configure Argo CD SSO, even if users do not use the UI directly, since users can only do local development in projects their groups have write access to.

Once implemented however, assuming it remains understood, it should be low-maintenance and provide ample opportunities for very simple and flexible automation.

In general, this approach is a trade-off. Initial setup will be difficult, but ultimately it abstracts away complexity while also providing a simple, secure, flexible, and self-service experience for app teams. Most importantly, it provides app teams with a way to do local development on their applications, and fully manage them within the Argo CD UI, which will allow users to troubleshoot their applications much more effectively.

## FAQ

### Why not just use a single ApplicationSet?

I found this difficult to reason about, given the one-to-many relationship between Projects and Applications.

### Why are the ApplicationSets managed by an Application?

This allows the ApplicationSets to be fully managed by Argo, meaning that we can define sync order between them, use the Argo CD UI to see their status, and so on. It also makes bootstrapping new clusters easier.

### Why does there need to be two Applications for each app?

This is nessessary to enable conditional isolation of the user's Application, i.e. taking control of namespace creation and policy, while still allowing the user to manage the majority of the Application themselves, via the Argo CD UI/CLI and/or commits to their git repo.

## Remaining Issues

Problems with this approach that I think could be solved with a bit of work:

- Integration with argocd-autopilot, argocd-image-updater, etc.
- Approach for multiple GitOps styles, i.e. both "manifests in app repo" and "manifests in infra monorepo".
- Approach for sharding the management repositories, e.g. creating a Project and allowing all other aspects of the system to be managed by the Project owners, without risk of namespace collision.

## Bootstrap

```sh
kubectl apply -f applications-multitenancy/applications.yaml
```
