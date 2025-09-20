import charts.securecodebox.api.v1 as securecodeboxv1

import securecodebox_scanners_base

app = securecodebox_scanners_base.app | {
    extraResources: {
        kubeHunter = securecodeboxv1.ScheduledScan {
            metadata.name = "kube-hunter"
            spec: {
                interval = "24h"
                successfulJobsHistoryLimit = 3
                failedJobsHistoryLimit = 5
                scanSpec: {
                    scanType = "kube-hunter"
                    resourceMode = "clusterWide"
                    parameters = [
                        "--pod"
                    ]
                }
            }
        }
        nmap = securecodeboxv1.ScheduledScan {
            metadata.name = "nmap"
            spec: {
                interval = "24h"
                successfulJobsHistoryLimit = 3
                failedJobsHistoryLimit = 5
                scanSpec: {
                    scanType = "nmap"
                    parameters = [
                        "--privileged"
                        "--reason"
                        "--script=safe"
                        "-v"
                        "-p1-65535" # Scan all ports
                        "-T3"       # Timing, 0-5, higher is faster.
                        "-sV"       # Probe open ports to determine service/version info
                        "-Pn"       # No ping
                        # "-6"      # Enable IPv6
                        "-sS"       # TCP SYN scan
                        # "-sT"     # TCP Connect() scan
                        # "-sA"     # TCP ACK scan
                        # "-sW"     # TCP Window scan
                        # "-sM"     # TCP Maimon scan
                        # "-sU"     # UDP scan
                        "wg.hel.macro.network"
                    ]
                }
            }
        }
    }
}
