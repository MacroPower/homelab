<p align="center">
  <a href="#"><img src="docs/img/k8shappy.png"></a>
  <br>
  <sup><sup>
    Art by <a href="https://twitter.com/SkeletalGadget">@SkeletalGadget</a>
  </sup></sup>
  <h3 align="center">Homelab</h2>
  <p align="center">
    IaC for my homelab and personal cloud
  </p>
  <p align="center">
    [ <a href="https://github.com/MacroPower/dotfiles">dotfiles</a> &#183;
    <a href="https://github.com/MacroPower/helm-charts">charts</a> &#183;
    <a href="https://github.com/MacroPower/containers">containers</a> &#183;
    <a href="https://jacobcolvin.com/posts/">blog</a> ]
  </p>
</p>

## 📖 Overview

This repository declares all of my infrastructure and Kubernetes clusters, both self-hosted and in [Hetzner Cloud](https://www.hetzner.com/). I also host all of my documentation here.

Admittedly, both usages of "all" describe the end goal of this repo, not the current state. But, I will get there some day.

---

## 🎨 Components

### Core

- [KCL](https://www.kcl-lang.io/): Configuration language; with Helm support via [kclipper](https://github.com/MacroPower/kclipper).
- [Talos](https://www.talos.dev): Immutable Kubernetes OS; built using [talhelper](https://github.com/budimanjojo/talhelper).
- [TrueNAS](https://www.truenas.com/): Big ZFS storage; runs small Talos containers for direct I/O.
- [Terraform](https://github.com/hashicorp/terraform): Declares any infrastructure not managed by Kubernetes.
- [Renovate](https://github.com/renovatebot/renovate): Automatic updates for applications via pull requests.

### Cluster management

- [Argo CD](https://github.com/argoproj/argo-cd): Reconciles Kubernetes clusters with this repository.
- [Spegel](https://goharbor.io): Stateless, fully transparent pull-through image cache.
- [Reloader](https://docs.stakater.com/reloader/): Automatic rollouts on ConfigMap/Secret updates.
- [Descheduler](https://sigs.k8s.io/descheduler): Evicts Pods to maintain zone and node balance.

### Networking

- [Cilium](https://cilium.io): eBPF-based CNI, BGP control plane, firewall, and more.
- [Envoy Gateway](https://gateway.envoyproxy.io/): Implements the Kubernetes Gateway API.
- [Cert Manager](https://cert-manager.io): Automatic Let's Encrypt certificates.
- [External DNS](https://kubernetes-sigs.github.io/external-dns/): Automatic DNS record management.
- [AdGuard Home](https://github.com/AdguardTeam/AdguardHome): DNS server with ad-blocking.
- [Wireguard](https://www.wireguard.com): Modern VPN tunnels.

### Security

- [External Secrets](https://external-secrets.io): Synchronizes secrets from [Doppler](https://www.doppler.com/) into Kubernetes.
- [Tetragon](https://tetragon.io/): eBPF-based security observability and runtime enforcement.
- [SecureCodeBox](https://www.securecodebox.io/): Continuous and automated security testing with familiar tools like Nmap, ZAP.

### Observability

- [Loki](https://grafana.com/oss/loki/): Log aggregation system.
- [Grafana](https://grafana.com): Visualization platform.
- [Tempo](https://grafana.com/oss/tempo/): Distributed tracing system.
- [Mimir](https://grafana.com/oss/mimir/): Prometheus-compatible monitoring system and TSDB.
- [Alloy](https://grafana.com/oss/alloy/): Grafana's distribution of OpenTelemetry collector.
- [Beyla](https://grafana.com/oss/beyla-ebpf/): Zero-touch eBPF auto-instrumentation (part of Alloy).
- [Robusta](https://home.robusta.dev): Alert and notification management.

### Storage

- [OpenEBS](https://openebs.io/): Manages local and replicated persistent volumes.
- [CloudNativePG](https://cloudnative-pg.io/): Manages highly-available, cloud-native Postgres clusters.
- [Dragonfly](https://www.dragonflydb.io): Highly-available, cloud-native Redis and Memcached implementation.

---

## 📂 Repository structure

This repository implements a **GitOps architecture**, primarily orchistrated by **Argo CD ApplicationSets** defined as [KCL](https://www.kcl-lang.io/) with [kclipper](https://github.com/MacroPower/kclipper). The repo's structure directly informs ApplicationSet behavior via matrix generators. The libraries used are based on KCL's [konfig](https://github.com/kcl-lang/konfig).

This structure enables a readable application hierarchy where each tenant can effectively function independently, i.e. somewhat mirroring an actual production multi-tenant platform. However, what would be individual repositories with their own access controls, releases, and so on, are instead represented as folders in this monorepo.

```yaml
.
├─📁 apps                     # KCL-based applications organized by tenants
│ ├─📁 argo                   #   Tenant: argo project
│ │ ├─📁 _tenant              #     Tenant-level shared configuration
│ │ │ ├─📁 base               #       Base tenant resources
│ │ │ │ └─📄 .tenant.yaml     #         Configures this tenant's "apps" ApplicationSet
│ │ │ └─📁 shared             #       Shared tenant resources
│ │ │   └─📄 .tenant.yaml     #         Configures this tenant's "shared" ApplicationSet
│ │ └─📁 cd                   #     Application: argo-cd namespace
│ │   ├─📁 base               #       Base app configuration
│ │   └─📁 mgmt               #       Management cluster environment
│ │     └─📄 .app.yaml        #         Configures this cluster's Argo CD Application
│ └─📁 ...                    #   Additional tenants
├─📁 appsets                  # ArgoCD ApplicationSets for multi-cluster deployment
│ └─📄 tenants.yaml           #   Matrix generator deploying tenant ApplicationSets
├─📁 bootstrap                # Cluster bootstrap configurations
│ └─📁 core                   #   Essential components (Cilium, ArgoCD)
├─📁 charts                   # Kclipper wrappers for Helm charts
│ ├─📁 argo_cd                #   Auto-generated ArgoCD kclipper wrapper
│ ├─📁 ...                    #   Additional auto-generated chart wrappers
│ └─📄 charts.k               #   Kclipper chart definitions
├─📁 clusters                 # Cluster configuration (Talos, KCL constants)
│ ├─📁 main                   #   Main cluster config
│ └─📁 mgmt                   #   Management cluster config
└─📁 konfig                   # Custom KCL library for Kubernetes abstractions
  ├─📁 models                 #   Core data models
  │ ├─📁 backend              #     Low-level Kubernetes resource models
  │ ├─📁 frontend             #     High-level application abstractions
  │ ├─📁 mixins               #     Reusable configuration mixins
  │ ├─📁 protocol             #     Interface definitions
  │ ├─📁 render               #     Rendering logic for YAML output
  │ └─📁 templates            #     Model templates
  └─📁 ...                    #   Utility packages, etc.
```

---

## ☁️ Dependencies

### Cloud Services

| Service                                              | Use                                                           | Cost          |
| ---------------------------------------------------- | ------------------------------------------------------------- | ------------- |
| [Hetzner Cloud](https://www.hetzner.com/)            | Cloud compute and storage                                     | $40/mo        |
| [Google Cloud](https://cloud.google.com/)            | Cloud storage                                                 | $20/mo        |
| [Cloudflare](https://www.cloudflare.com/)            | DNS, Certs, Proxy, WAF                                        | Free          |
| [Doppler](https://doppler.com/)                      | Secrets with [External Secrets](https://external-secrets.io/) | Free          |
| [GitHub](https://github.com/)                        | Hosting this repository and CI/CD workflows                   | Free          |
| [Robusta](https://home.robusta.dev/)                 | Alerts and notifications                                      | Free          |
| [Terraform Cloud](https://www.terraform.io/)         | Storing Terraform state                                       | Free          |
| [Grafana Cloud](https://grafana.com/products/cloud/) | Hosted Grafana / LGTM Stack                                   | Free          |
| [Auth0](https://auth0.com/)                          | IDP / Authentication and authorization platform               | Free          |
| [Unifi Site Manager](https://ui.com/)                | Multi-site Unifi gateway management                           | Free          |
|                                                      |                                                               | Total: $60/mo |

### Internet

| Provider | Plan             | Modem        | Speed (Down) | Speed (Up) | Latency        | Purpose         | Cost          |
| -------- | ---------------- | ------------ | ------------ | ---------- | -------------- | --------------- | ------------- |
| T-Mobile | Home Internet 5G | InvisaGig    | 600 Mbps     | 150 Mbps   | ~ 50ms (100mi) | Primary         | $40/mo        |
| Spectrum | Basic Cable      | Ubiquiti UCI | 300 Mbps     | 10 Mbps    | ~ 15ms (100mi) | Backup & Gaming | $50/mo        |
|          |                  |              |              |            |                |                 | Total: $90/mo |

### Electricity

| Item    | Consumption  | Rate      | Cost          |
| ------- | ------------ | --------- | ------------- |
| Homelab | ~ 400W (Avg) | $0.14/kWh | $45/mo        |
|         |              |           | Total: $45/mo |

---

## 🔧 Hardware

### Core

| Count | Device          | Memory | Disk         | OS      | Purpose              |
| ----- | --------------- | ------ | ------------ | ------- | -------------------- |
| 3     | Turing Pi 2     | 128MB  | 1GB NAND     | TPi BMC | 4-Node Cluster Board |
| 1     | Raspberry Pi 4B | 4GB    | 32GB SD Card | PiKVM   | Network KVM          |

### Management Cluster

| Count | Device           | Memory | Disk      | OS    | Purpose         |
| ----- | ---------------- | ------ | --------- | ----- | --------------- |
| 3     | Raspberry Pi CM4 | 8GB    | 32GB eMMC | Talos | Control Plane   |
| 3     | Turing RK1       | 32GB   | 1TB NVMe  | Talos | Workers (arm64) |

### Main Cluster

| Count | Device                     | Memory | Disk      | OS    | Purpose          |
| ----- | -------------------------- | ------ | --------- | ----- | ---------------- |
| 3     | Turing RK1                 | 32GB   | 1TB NVMe  | Talos | Control Plane    |
| 3     | Supermicro M11SDV-8C+-LN4F | 128GB  | 4TB SSD   | Talos | Workers (x86)    |
| 3     | Turing RK1                 | 32GB   | 1TB NVMe  | Talos | Workers (arm64)  |
| 1     | TrueNAS Mini R             | 64GB   | 200TB HDD | SCALE | Storage + Worker |

### Networking

| Count | Device                       | Eth Interfaces | SFP Interfaces | Platform | Purpose                   |
| ----- | ---------------------------- | -------------- | -------------- | -------- | ------------------------- |
| 1     | Ubiquiti UDM-SE              | 1x 2.5G        | 2x 10G         | UniFi OS | Router & Security Gateway |
| 1     | Ubiquiti U6-Pro              | 1x 1G          | N/A            | UniFi OS | WiFi 6 Access Point       |
| 1     | Ubiquiti USW-Pro-Aggregation | N/A            | 28x 10G        | UniFi OS | L3 Aggregation Switch     |
| 1     | Ubiquiti USW-Pro-24          | 24x 1G         | 2x 10G         | UniFi OS | L3 Switch                 |
| 1     | Ubiquiti USW-Pro-24-POE      | 24x 1G         | 2x 10G         | UniFi OS | L3 PoE Switch             |
| 2     | WattBox WB-800-IPVM-12       | 1x 1G          | N/A            | OvrC     | IP Controlled Metered PDU |
| 2     | WattBox WB-800-IPVM-6        | 1x 1G          | N/A            | OvrC     | IP Controlled Metered PDU |
| 1     | WattBox WB-800VPS-IPVM-18    | 1x 1G          | N/A            | OvrC     | IP Controlled Metered PDU |

---

## 🤝 Thanks

Over time I've taken a ton of inspiration from the K8s@Home / home-ops community: [onedr0p](https://github.com/onedr0p/flux-cluster-template), [szinn](https://github.com/szinn/k8s-homelab), [budimanjojo](https://github.com/budimanjojo/home-cluster), [buroa](https://github.com/buroa/k8s-gitops), [coolguy1771](https://github.com/coolguy1771/home-ops), and many others.

Technically however, I hope this repo is quite unique. I've intentionally tried to make some uncommon choices to learn more and venture outside my comfort zone a bit. So, I hope that in the very least, this repo will provide anyone looking with some interesting and unique ideas. 🙂

---

## 🔏 License

This project is licensed under the Apache-2.0 license, primarily because it's very compatible with a lot of the projects I enjoy stealing code from.

For more details, see [LICENSE](./LICENSE).

Ultimately though, I have a WTFPL mindset about any content produced by/for myself. If you like anything you see here, feel free to use it however you want (yes, that includes the peepos), just don't sue me if my code blows up your cluster. If you're feeling especially nice, links back to this repo are always appreciated (for the SEO, or whatever).

---

<p align="center">
  <a href="#"><img src="docs/img/peepoK8S.png"></a>
</p>
