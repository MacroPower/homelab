import helm

charts: helm.Charts = {
    kubelet_csr_approver: {
        chart = "kubelet-csr-approver"
        repoURL = "https://postfinance.github.io/kubelet-csr-approver"
        targetRevision = "1.2.12"
        schemaGenerator = "AUTO"
    }
    cilium: {
        chart = "cilium"
        repoURL = "https://helm.cilium.io"
        targetRevision = "1.18.3"
        schemaGenerator = "VALUE-INFERENCE"
        crdGenerator = "PATH"
        crdPaths = [
            "https://doc.crds.dev/raw/github.com/cilium/cilium"
        ]
    }
    tetragon: {
        chart = "tetragon"
        repoURL = "https://helm.cilium.io"
        targetRevision = "1.6.0"
        schemaGenerator = "VALUE-INFERENCE"
        crdGenerator = "PATH"
        crdPaths = [
            "https://doc.crds.dev/raw/github.com/cilium/tetragon"
        ]
    }
    external_secrets: {
        chart = "external-secrets"
        repoURL = "https://charts.external-secrets.io/"
        targetRevision = "0.20.2"
        schemaGenerator = "VALUE-INFERENCE"
        crdGenerator = "TEMPLATE"
        values: {
            crds: {
                conversion: {
                    enabled = False
                }
            }
        }
    }
    argo_cd: {
        chart = "argo-cd"
        repoURL = "https://argoproj.github.io/argo-helm"
        targetRevision = "8.6.4"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    grafana_operator: {
        chart = "grafana-operator"
        repoURL = "oci://ghcr.io/grafana/helm-charts/grafana-operator"
        targetRevision = "v5.20.0"
        schemaGenerator = "AUTO"
        values: {
            rbac: {
                create = False
            }
        }
    }
    descheduler: {
        chart = "descheduler"
        repoURL = "https://kubernetes-sigs.github.io/descheduler/"
        targetRevision = "0.34.0"
        schemaGenerator = "AUTO"
    }
    metrics_server: {
        chart = "metrics-server"
        repoURL = "https://kubernetes-sigs.github.io/metrics-server/"
        targetRevision = "3.13.0"
        schemaGenerator = "AUTO"
    }
    cert_manager: {
        chart = "cert-manager"
        repoURL = "https://charts.jetstack.io"
        targetRevision = "v1.19.1"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
        values: {
            crds: {
                enabled = True
            }
        }
    }
    dragonfly_operator: {
        chart = "dragonfly-operator"
        repoURL = "oci://ghcr.io/dragonflydb/dragonfly-operator/helm/dragonfly-operator"
        targetRevision = "v1.3.0"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    external_dns: {
        chart = "external-dns"
        repoURL = "https://kubernetes-sigs.github.io/external-dns/"
        targetRevision = "1.19.0"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    cloudnative_pg: {
        chart = "cloudnative-pg"
        repoURL = "https://cloudnative-pg.io/charts/"
        targetRevision = "0.26.1"
        schemaGenerator = "VALUE-INFERENCE"
        crdGenerator = "TEMPLATE"
    }
    openebs: {
        chart = "openebs"
        repoURL = "https://openebs.github.io/openebs"
        targetRevision = "4.3.3"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    seaweedfs: {
        chart = "seaweedfs"
        repoURL = "https://seaweedfs.github.io/seaweedfs/helm"
        targetRevision = "4.0.400"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    loki: {
        chart = "loki"
        repoURL = "https://grafana.github.io/helm-charts"
        targetRevision = "6.45.2"
        schemaGenerator = "VALUE-INFERENCE"
        crdGenerator = "NONE"
    }
    tempo: {
        chart = "tempo-distributed"
        repoURL = "https://grafana.github.io/helm-charts"
        targetRevision = "1.52.7"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    mimir: {
        chart = "mimir-distributed"
        repoURL = "https://grafana.github.io/helm-charts"
        targetRevision = "5.8.0"
        schemaGenerator = "NONE"
        crdGenerator = "NONE"
    }
    k8s_monitoring: {
        chart = "k8s-monitoring"
        repoURL = "https://grafana.github.io/helm-charts"
        targetRevision = "3.5.6"
        schemaGenerator = "VALUE-INFERENCE"
        crdGenerator = "TEMPLATE"
        values: {
            cluster: {name = "kcl"}
            destinationsMap: {
                mimir: {"type" = "prometheus"}
            }
            "alloy-metrics": {
                enabled = True
            }
            prometheusOperatorObjects: {
                enabled = True
                crds: {deploy = True}
            }
        }
    }
    grafana_pdc_agent: {
        chart = "pdc-agent"
        repoURL = "https://grafana.github.io/helm-charts"
        targetRevision = "0.0.1"
        schemaGenerator = "AUTO"
        values: {
            cluster = "kcl"
            hostedGrafanaId = "0"
            tokenSecretName = "kcl"
        }
    }
    sonarr: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    radarr: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    configarr: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    prowlarr: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    envoy_gateway: {
        chart = "gateway-helm"
        repoURL = "oci://docker.io/envoyproxy/gateway-helm"
        targetRevision = "1.5.4"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    spegel: {
        chart = "spegel"
        repoURL = "oci://ghcr.io/spegel-org/helm-charts/spegel"
        targetRevision = "0.4.0"
        schemaGenerator = "AUTO"
    }
    reloader: {
        chart = "reloader"
        repoURL = "https://stakater.github.io/stakater-charts"
        targetRevision = "2.2.5"
        schemaGenerator = "VALUE-INFERENCE"
    }
    homepage: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    adguard: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "NONE"
    }
    robusta: {
        chart = "robusta"
        repoURL = "https://robusta-charts.storage.googleapis.com"
        targetRevision = "0.29.1"
        schemaGenerator = "AUTO"
        values: {
            clusterName = "kcl"
            sinksConfig = [{
                robusta_sink: {name = "robusta_ui_sink"}
            }]
        }
    }
    tcpm: {
        chart = "twitch-channel-points-miner"
        repoURL = "https://jacobcolvin.com/helm-charts/"
        targetRevision = "0.1.0"
        schemaGenerator = "AUTO"
    }
    volsync: {
        chart = "volsync"
        repoURL = "https://backube.github.io/helm-charts/"
        targetRevision = "0.13.1"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    securecodebox: {
        chart = "operator"
        repoURL = "oci://ghcr.io/securecodebox/helm/operator"
        targetRevision = "5.1.0"
        schemaGenerator = "AUTO"
        crdGenerator = "AUTO"
    }
    securecodebox_kube_hunter: {
        chart = "kube-hunter"
        repoURL = "oci://ghcr.io/securecodebox/helm/kube-hunter"
        targetRevision = "5.1.0"
        schemaGenerator = "AUTO"
    }
    securecodebox_nmap: {
        chart = "nmap"
        repoURL = "oci://ghcr.io/securecodebox/helm/nmap"
        targetRevision = "5.1.0"
        schemaGenerator = "AUTO"
    }
    securecodebox_generic_webhook: {
        chart = "generic-webhook"
        repoURL = "oci://ghcr.io/securecodebox/helm/generic-webhook"
        targetRevision = "5.1.0"
        schemaGenerator = "AUTO"
    }
    webhook: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    osrs_ge_exporter: {
        chart = "osrs-ge-exporter"
        repoURL = "https://jacobcolvin.com/helm-charts/"
        targetRevision = "0.4.0"
        schemaGenerator = "AUTO"
    }
    wakatime_exporter: {
        chart = "wakatime-exporter"
        repoURL = "https://jacobcolvin.com/helm-charts/"
        targetRevision = "0.1.1"
        schemaGenerator = "AUTO"
    }
    readme_updater: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    opencloud: {
        chart = "opencloud"
        repoURL = "https://jacobcolvin.com/helm-charts"
        targetRevision = "0.2.3"
        schemaGenerator = "AUTO"
        crdGenerator = "NONE"
    }
    nack: {
        chart = "nack"
        repoURL = "https://nats-io.github.io/k8s/helm/charts/"
        targetRevision = "0.30.0"
        schemaGenerator = "AUTO"
        crdGenerator = "TEMPLATE"
    }
    nats: {
        chart = "nats"
        repoURL = "https://nats-io.github.io/k8s/helm/charts/"
        targetRevision = "1.3.16"
        schemaGenerator = "AUTO"
    }
    qbittorrent: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
    crossplane: {
        chart = "crossplane"
        repoURL = "https://charts.crossplane.io/stable"
        targetRevision = "2.0.2"
        schemaGenerator = "AUTO"
        crdGenerator = "PATH"
        crdPaths = [
            "https://doc.crds.dev/raw/github.com/crossplane/crossplane@v2.0.2"
        ]
    }
    opentofu: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "NONE"
        crdGenerator = "PATH"
        crdPaths = [
            "https://raw.githubusercontent.com/upbound/provider-opentofu/refs/tags/v1.0.0/package/crds/opentofu.m.upbound.io_clusterproviderconfigs.yaml"
            "https://raw.githubusercontent.com/upbound/provider-opentofu/refs/tags/v1.0.0/package/crds/opentofu.m.upbound.io_providerconfigs.yaml"
            "https://raw.githubusercontent.com/upbound/provider-opentofu/refs/tags/v1.0.0/package/crds/opentofu.m.upbound.io_workspaces.yaml"
        ]
    }
    truecommand: {
        chart = "app-template"
        repoURL = "oci://ghcr.io/bjw-s-labs/helm/app-template"
        targetRevision = "4.4.0"
        schemaGenerator = "AUTO"
    }
}
