import charts.descheduler
import konfig.models.frontend
import konfig.models.templates.networkpolicy
import kube

app = frontend.App {
    name = "descheduler"
    tenantName = kube.tenant.name

    networkPolicies = {
        denyDefault = networkpolicy.denyDefault
        kubeDNSEgress = networkpolicy.kubeDNSEgress
        kubeAPIServerEgress = networkpolicy.kubeAPIServerEgress
    }

    charts.descheduler = descheduler.Chart {
        values = descheduler.Values {
            schedule = "*/10 * * * *"
            deschedulerPolicy.profiles = [
                {
                    name = "default"
                    pluginConfig = [
                        {
                            name = "DefaultEvictor"
                            args = {
                                ignorePvcPods = False
                                evictLocalStoragePods = True
                            }
                        }
                        {
                            name = "RemoveDuplicates"
                        }
                        {
                            name = "RemovePodsHavingTooManyRestarts"
                            args = {
                                podRestartThreshold = 100
                                includingInitContainers = True
                            }
                        }
                        {
                            name = "RemovePodsViolatingNodeAffinity"
                            args = {
                                nodeAffinityType = [
                                    "requiredDuringSchedulingIgnoredDuringExecution"
                                ]
                            }
                        }
                        {
                            name = "RemovePodsViolatingNodeTaints"
                        }
                        {
                            name = "RemovePodsViolatingInterPodAntiAffinity"
                        }
                        {
                            name = "RemovePodsViolatingTopologySpreadConstraint"
                        }
                        {
                            name = "LowNodeUtilization"
                            args = {
                                thresholds = {
                                    cpu = 20
                                    memory = 20
                                    pods = 20
                                }
                                targetThresholds = {
                                    cpu = 50
                                    memory = 50
                                    pods = 50
                                }
                            }
                        }
                    ]
                    plugins = {
                        balance = {
                            enabled = [
                                "RemoveDuplicates"
                                "RemovePodsViolatingTopologySpreadConstraint"
                                "LowNodeUtilization"
                            ]
                        }
                        deschedule = {
                            enabled = [
                                "RemovePodsHavingTooManyRestarts"
                                "RemovePodsViolatingNodeTaints"
                                "RemovePodsViolatingNodeAffinity"
                                "RemovePodsViolatingInterPodAntiAffinity"
                            ]
                        }
                    }
                }
            ]
            resources.requests = {
                cpu = "50m"
                memory = "250Mi"
            }
            resources.limits = {
                memory = "250Mi"
            }
            serviceMonitor = {
                enabled = True
                insecureSkipVerify = True
                interval = "1s"
                serverName = None
                metricRelabelings = [
                    {
                        action = "keep"
                        regex = "descheduler_(build_info|pods_evicted)"
                        sourceLabels = [
                            "__name__"
                        ]
                    }
                ]
                relabelings = [
                    {
                        sourceLabels = [
                            "__meta_kubernetes_pod_node_name"
                        ]
                        separator = ";"
                        regex = r"""^(.*)$"""
                        targetLabel = "nodename"
                        replacement = r"""$1"""
                        action = "replace"
                    }
                ]
            }
        }
    }
}
