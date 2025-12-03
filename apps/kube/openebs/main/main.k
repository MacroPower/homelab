import file

import konfig.files
import konfig.objects

import kube_openebs_base
import charts.openebs
import k8s.api.apps.v1 as appsv1
import k8s.api.core.v1 as corev1
import k8s.api.storage.v1 as storagev1

_baseValues = kube_openebs_base.app.charts.openebs.values
_envValues = files.read_yaml(file.current(), "values.yaml")
_values = objects.json_merge_patch(_baseValues, _envValues)

_zfsPoolManagerLabels = {
    "app.kubernetes.io/name": "openebs-zfs-node"
    "app.kubernetes.io/instance": "openebs-zfs-pool-manager"
}

_volDev = corev1.Volume {
    name = "dev"
    hostPath.path = "/dev"
}

_volProc = corev1.Volume {
    name = "proc"
    hostPath.path = "/proc"
}

_volSys = corev1.Volume {
    name = "sys"
    hostPath.path = "/sys"
}

_volLib = corev1.Volume {
    name = "lib"
    hostPath.path = "/lib/modules"
}

_zfsPoolManager = appsv1.DaemonSet {
    metadata: {
        name = "openebs-zfs-pool-manager"
        labels = _zfsPoolManagerLabels
    }
    spec: {
        selector.matchLabels = _zfsPoolManagerLabels
        template: {
            metadata.labels = _zfsPoolManagerLabels
            spec: {
                hostNetwork = True
                hostPID = True
                initContainers = [
                    {
                        name = "zfs-init"
                        image = "ubuntu:24.04"
                        command = [
                            "/bin/bash"
                            "-c"
                            file.read(files.abs_path(file.current(), "zfs-init.sh"))
                        ]
                        securityContext = {
                            privileged = True
                        }
                        volumeMounts = [
                            {
                                name = _volDev.name
                                mountPath = _volDev.hostPath.path
                            }
                            {
                                name = _volProc.name
                                mountPath = _volProc.hostPath.path
                            }
                            {
                                name = _volSys.name
                                mountPath = _volSys.hostPath.path
                                readOnly = True
                            }
                            {
                                name = _volLib.name
                                mountPath = _volLib.hostPath.path
                                readOnly = True
                            }
                        ]
                    }
                ]
                containers = [
                    {
                        name = "pause"
                        image = "registry.k8s.io/pause:3.9"
                    }
                ]
                volumes = [
                    _volDev
                    _volProc
                    _volSys
                    _volLib
                ]
            }
        }
    }
}

_zfsPostgresStorageClass = storagev1.StorageClass {
    metadata: {
        name = "openebs-zfs-postgres"
    }
    provisioner = "zfs.csi.openebs.io"
    parameters = {
        poolname = "tank"
        fstype = "xfs"
        compression = "zstd-fast"
        volblocksize = "16k"
    }
    reclaimPolicy = "Retain"
    volumeBindingMode = "WaitForFirstConsumer"
}

_zfsEtcdStorageClass = storagev1.StorageClass {
    metadata: {
        name = "openebs-zfs-etcd"
    }
    provisioner = "zfs.csi.openebs.io"
    parameters = {
        poolname = "tank"
        fstype = "xfs"
        volblocksize = "8k"
    }
    reclaimPolicy = "Retain"
    volumeBindingMode = "WaitForFirstConsumer"
}

_mayastorHosts = ["kmain07", "kmain08", "kmain09"]

_diskPools = {"diskPool_${hostname}": {
    apiVersion = "openebs.io/v1beta3"
    kind = "DiskPool"
    metadata: {
        name = "pool-${hostname}"
        annotations = {
            "argocd.argoproj.io/sync-options": "SkipDryRunOnMissingResource=true"
        }
    }
    spec = {
        node = hostname
        disks = ["aio:///dev/disk/by-partlabel/r-mayastor-pool"]
    }
} for hostname in _mayastorHosts}

app = kube_openebs_base.app | {
    charts.openebs.values = _values | openebs.Values {}
    extraResources: {
        zfsPoolManager = _zfsPoolManager
        zfsPostgresStorageClass = _zfsPostgresStorageClass
        zfsEtcdStorageClass = _zfsEtcdStorageClass
    } | _diskPools
}
