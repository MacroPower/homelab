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
</p>

## 📖 Overview

This repository declares all of my infrastructure and Kubernetes clusters, both self-hosted and in [Hetzner Cloud](https://www.hetzner.com/). I also host all of my documentation here.

Admittedly, both usages of "all" describe the end goal of this repo, not the current state. But, I will get there some day.

---

## 🎨 Components

### Infrastructure management

- [Terraform](https://github.com/hashicorp/terraform): Bootstraps and manages infrastructure needed for Kubernetes.

### Cluster management

- [Talos](https://www.talos.dev): Immutable Kubernetes OS; built using [talhelper](https://github.com/budimanjojo/talhelper).
- [Argo CD](https://github.com/argoproj/argo-cd): Reconciles kubernetes clusters with this repository.
- [Jsonnet](https://jsonnet.org/): Configuration language I use to describe Argo applications.
- [Renovate](https://github.com/renovatebot/renovate): Automatic updates for applications via pull requests.

### Secrets

- [Doppler](https://www.doppler.com/): Hosted secrets management platform.
- [External Secrets](https://external-secrets.io): Synchronizes secrets from Doppler into Kubernetes.

### Networking

- [Cilium](https://cilium.io): eBPF-based CNI & service mesh.
- [Authentik](https://goauthentik.io): Identity Provider.
- [MetalLB](https://metallb.universe.tf/): Load-balancer implementation supporting L2 & BGP.
- [Traefik](https://traefik.io): Ingress controller & reverse proxy.
- [AdGuard Home](https://github.com/AdguardTeam/AdguardHome): DNS server with ad-blocking.

### Observability

- [Prometheus](https://prometheus.io): Monitoring system & TSDB.
- [Jaeger](https://www.jaegertracing.io): Distributed tracing system.
- [Loki](https://grafana.com/oss/loki/): Log aggregation system.
- [Vector](https://vector.dev): Log collector, transformer, and router.
- [Grafana](https://grafana.com): Visualization platform.
- [Robusta](https://home.robusta.dev): Alerts / notifications and runbook automation.

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

| Device                      | Count | OS Disk Size    | Data Disk Size     | Ram   | Operating System | Purpose                       |
| --------------------------- | ----- | --------------- | ------------------ | ----- | ---------------- | ----------------------------- |
| Turing Pi 2                 | 3     | 1GB NAND        | N/A                | 128MB | TPi BMC Firmware | 4-Node Cluster Board          |
| Raspberry Pi CM4            | 3     | 32GB eMMC       | N/A                | 8GB   | Talos Linux      | Kubernetes Control Plane      |
| Supermicro M11SDV-8C+-LN4F  | 3     | 64GB SATADOM \* | 4TB SSD            | 128GB | Talos Linux      | Kubernetes Workers (x86)      |
| Turing RK1 \*               | 3     | 32GB eMMC       | 1TB SSD            | 32GB  | Talos Linux      | Kubernetes Workers (arm64)    |
| Supermicro X10SRA / E5-2690 | 1     | 16GB Flash      | 46TB HDD + 2TB SSD | 16GB  | Unraid           | Storage Server                |
| Netgate XG-7100             | 1     | 32GB eMMC       | N/A                | 8GB   | pfSense          | Router / Security Gateway     |
| TP-Link T1700G-28TQ         | 1     | N/A             | N/A                | N/A   | N/A              | 1G Ethernet / 10G SFP+ Switch |
| MikroTik CRS317-1G-16S+RM   | 1     | N/A             | N/A                | N/A   | N/A              | 10G SFP+ Switch               |
| Raspberry Pi 4B             | 1     | 32GB SD Card    | N/A                | 4GB   | PiKVM            | Network KVM                   |
| Wattbox WB-800-IPVM         | 1     | N/A             | N/A                | N/A   | N/A              | PDU                           |

<sup>\* == Pending</sup>

---

## 🤝 Thanks

Over time I've taken a ton of inspiration from the K8s@Home community, notably:

- https://github.com/onedr0p/flux-cluster-template
- https://github.com/szinn/k8s-homelab
- https://github.com/budimanjojo/home-cluster
- https://github.com/buroa/k8s-gitops
- https://github.com/coolguy1771/home-ops

And probably more that I've forgotten about over time.

Technically however, I hope this repo is quite unique. I've intentionally tried to make some uncommon choices to learn more and venture outside my comfort zone a bit. So, I hope that in the very least, this repo will provide anyone looking with some interesting and unique ideas. 🙂

---

## 🔏 License

See [LICENSE](./LICENSE)

---

<p align="center">
  <a href="#"><img src="docs/img/peepoK8S.png"></a>
</p>
