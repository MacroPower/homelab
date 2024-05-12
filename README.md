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

### Infrastructure management

- [Terraform](https://github.com/hashicorp/terraform): Bootstraps and manages infrastructure needed for Kubernetes.
- [Crossplane](https://crossplane.io): Kubernetes-native infrastructure management.

### Cluster management

- [Talos](https://www.talos.dev): Immutable Kubernetes OS; built using [talhelper](https://github.com/budimanjojo/talhelper).
- [Argo CD](https://github.com/argoproj/argo-cd): Reconciles kubernetes clusters with this repository.
- [Kyverno](https://kyverno.io): Policy engine supporting validate, mutate, generate, and cleanup rules.
- [Harbor](https://goharbor.io): Artifact registry with pull-through cache and vulnerability scanning.
- [Jsonnet](https://jsonnet.org/): Configuration language I use to describe Argo applications.
- [Renovate](https://github.com/renovatebot/renovate): Automatic updates for applications via pull requests.

### Secrets

- [Doppler](https://www.doppler.com/): Hosted secrets management platform.
- [External Secrets](https://external-secrets.io): Synchronizes secrets from Doppler into Kubernetes.

### Networking

- [Cilium](https://cilium.io): eBPF-based CNI & service mesh.
- [Traefik](https://traefik.io): Ingress controller & reverse proxy.
- [Cert Manager](https://cert-manager.io): Automatic Let's Encrypt certificates.
- [AdGuard Home](https://github.com/AdguardTeam/AdguardHome): DNS server with ad-blocking.
- [Wireguard](https://www.wireguard.com): Modern VPN tunnels; implemented using [wireguard-operator](https://github.com/jodevsa/wireguard-operator).

### Security

- [Authentik](https://goauthentik.io): Identity Provider.
- [Tetragon](https://tetragon.io/): eBPF-based security observability and runtime enforcement.
- [SecureCodeBox](https://www.securecodebox.io/): Continuous and automated security testing with familiar tools like Nmap, ZAP.
- [Trivy](https://aquasecurity.github.io/trivy): Kubernetes and container vulnerability scanner.

### Observability

- [Prometheus](https://prometheus.io): Monitoring system & TSDB.
- [Jaeger](https://www.jaegertracing.io): Distributed tracing system.
- [Loki](https://grafana.com/oss/loki/): Log aggregation system.
- [Vector](https://vector.dev): Log collector, transformer, and router.
- [OTEL Collector](https://opentelemetry.io/docs/collector/): Trace/metric collector, transformer, and router.
- [Grafana](https://grafana.com): Visualization platform.
- [Robusta](https://home.robusta.dev): Alerts / notifications and runbook automation.
- [Inspektor Gadget](https://www.inspektor-gadget.io/): eBPF-based gadgets to debug and inspect Kubernetes apps and resources.

### Storage

- [Rook](https://rook.io): Storage operator for Ceph.
- [Ceph](https://ceph.io): Distributed object, block, and file storage.

---

## 📂 Repository structure

Overview of this repo's structure, there's more info in the README files for each:

```sh
📁 applications  # Kubernetes applications
├─📁 base          # Application base config
├─📁 environments  # Application cluster customizations
│ ├─📁 hcloud        # Customizations for Hetzner cluster
│ ├─📁 home          # Customizations for home cluster
│ └─📁 seedbox       # Customizations for seedbox cluster
└─📁 lib           # Jsonnet libraries

📁 terraform     # IaC defined via Terraform
├─📁 home          # IaC for home
├─📁 hcloud        # IaC for Hetzner Cloud
└─📁 hcloud-robot  # IaC for Hetzner Cloud (Robot)
```

---

## ☁️ Cloud Dependencies

Although the majority of my infrastructure and workloads are self-hosted, there are certain key components of my setup that rely on cloud services.

| Service                                              | Use                                                            | Cost           |
| ---------------------------------------------------- | -------------------------------------------------------------- | -------------- |
| [Hetzner Cloud](https://www.hetzner.com/)            | Cloud compute and storage                                      | ~$40/mo        |
| [AWS](https://aws.amazon.com/)                       | Cloud cold storage (S3 Deep Glacier)                           | ~$10/mo        |
| [Google Cloud](https://cloud.google.com/)            | Cloud storage                                                  | ~$20/mo        |
| [Cloudflare](https://www.cloudflare.com/)            | DNS, Certs, Proxy, WAF                                         | Free           |
| [Doppler](https://doppler.com/)                      | Secrets with [External Secrets](https://external-secrets.io/)  | Free           |
| [GitHub](https://github.com/)                        | Hosting this repository and continuous integration/deployments | Free           |
| [Renovate](https://github.com/renovatebot/renovate)  | Automatic updates for applications via pull requests           | Free           |
| [Docker Hub](https://hub.docker.com/)                | Docker image registry                                          | Free           |
| [Robusta](https://home.robusta.dev/)                 | Alerts / notifications and runbook automation                  | Free           |
| [Terraform Cloud](https://www.terraform.io/)         | Storing Terraform state                                        | Free           |
| [Grafana Cloud](https://grafana.com/products/cloud/) | Hosted Grafana & Prometheus, used for misc public projects     | Free           |
|                                                      |                                                                | Total: ~$70/mo |

---

## 🔧 Hardware

### Computing

| Count | Device                     | OS Disk Size | Data Disk Size      | Ram   | Operating System | Purpose                    |
| ----- | -------------------------- | ------------ | ------------------- | ----- | ---------------- | -------------------------- |
| 3     | Turing Pi 2                | 1GB NAND     | 32GB SD Card        | 128MB | TPi BMC Firmware | 4-Node Cluster Board       |
| 3     | Raspberry Pi CM4           | 32GB eMMC    | N/A                 | 8GB   | Talos Linux      | Kubernetes Control Plane   |
| 3     | Supermicro M11SDV-8C+-LN4F | 64GB SATADOM | 4TB SSD             | 128GB | Talos Linux      | Kubernetes Workers (x86)   |
| 3     | Turing RK1 \*              | 32GB eMMC    | 1TB SSD             | 32GB  | Talos Linux      | Kubernetes Workers (arm64) |
| 1     | TrueNAS Mini R             | 500GB SSD    | 200TB HDD + 2TB SSD | 64GB  | TrueNAS SCALE    | Storage Server             |
| 1     | Raspberry Pi 4B            | 32GB SD Card | N/A                 | 4GB   | PiKVM            | Network KVM                |

<sup>\* == Pending</sup>

### Networking

| Count | Device                       | Eth Interfaces | SFP Interfaces | Platform | Purpose                   |
| ----- | ---------------------------- | -------------- | -------------- | -------- | ------------------------- |
| 1     | Ubiquiti UDM-SE              | 1x 2.5G        | 2x 10G         | UniFi OS | Router & Security Gateway |
| 1     | Ubiquiti UCI                 | 1x 2.5G        | N/A            | UniFi OS | DOCSIS 3.1 Cable Modem    |
| 1     | Ubiquiti U6-Pro              | 1x 1G          | N/A            | UniFi OS | WiFi 6 Access Point       |
| 1     | Ubiquiti USW-Pro-Aggregation | N/A            | 28x 10G        | UniFi OS | L3 Aggregation Switch     |
| 1     | Ubiquiti USW-Pro-24          | 24x 1G         | 2x 10G         | UniFi OS | L3 Switch                 |
| 1     | Ubiquiti USW-Pro-24-POE      | 24x 1G         | 2x 10G         | UniFi OS | L3 PoE Switch             |
| 2     | WattBox WB-800-IPVM          | 1x 1G          | N/A            | OvrC     | IP Controlled Metered PDU |
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
