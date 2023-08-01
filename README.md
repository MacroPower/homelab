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

My clusters use [Talos](https://talos.dev/), as well as [k3s-on-MicroOS](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner). Most of the configuration is written in [Jsonnet](https://jsonnet.org/).

---

## 🎨 Components

### Infrastructure management

- [Terraform](https://github.com/hashicorp/terraform): Bootstraps and manages infrastructure needed for Kubernetes.

### Cluster management

- [Talos](https://www.talos.dev): Immutable [Kubernetes](https://kubernetes.io/) OS; built using [talhelper](https://github.com/budimanjojo/talhelper).
- [Argo CD](https://github.com/argoproj/argo-cd): Reconciles kubernetes clusters with this repository.
- [Jsonnet](https://jsonnet.org/): Configuration language I use to describe Argo applications.
- [Renovate](https://github.com/renovatebot/renovate): Automatic updates for applications via pull requests.

### Secrets

- [Doppler](https://www.doppler.com/): Hosted secrets management platform.
- [External Secrets](https://external-secrets.io): Synchronizes secrets from Doppler into Kubernetes.

### Networking

- [Cilium](https://cilium.io): eBPF-based CNI.
- [Linkerd](https://linkerd.io): Service mesh, allows for multi-cluster communication.
- [Authentik](https://goauthentik.io): Identity Provider.
- [MetalLB](https://metallb.universe.tf/): Load-balancer implementation supporting L2 & BGP.

### Observability

- [Prometheus](https://prometheus.io): Monitoring system & TSDB.
- [Grafana](https://grafana.com): Visualization platform.

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

And probably more that I've forgotten about over time.

Technically however, I hope this repo is quite unique. I've intentionally tried to make some uncommon choices to learn more and venture outside my comfort zone a bit. So, I hope that in the very least, this repo will provide anyone looking with some interesting and unique ideas. 🙂

---

## 🔏 License

See [LICENSE](./LICENSE)
