import k8s.api.core.v1 as corev1
import k8s.api.apps.v1 as appsv1
import manifests

# In-cluster git mirror for the Talos-in-Docker test cluster.
#
# Cilium excludes the node's own docker subnet from masquerade, so pods cannot
# reach a git server on the docker bridge gateway -- but they CAN reach the
# node IP (like the host-network apiserver), and so can the host over the
# docker bridge. So the mirror runs as a hostNetwork pod listening on
# <node>:9418: Argo CD's repo-server clones git://<node>:9418/homelab.git and
# the host pushes working-tree snapshots to the same address (see the
# tald:git-push task). The repo lives on an emptyDir and is re-seeded by
# `tald:push`, so it survives nothing but that is fine -- the source of truth
# is always your working tree.

_namespace = "git-system"
_labels = {app = "git"}

# alpine/git ships core git only; git-daemon is a subpackage.
_daemonScript = """set -e
apk add --no-cache git-daemon >/dev/null
REPO=/srv/git/homelab.git
mkdir -p "$REPO"
if [ ! -d "$REPO/objects" ]; then
  git init --bare "$REPO"
fi
git config --global --add safe.directory "$REPO"
exec git daemon --verbose --reuseaddr --enable=receive-pack --base-path=/srv/git --export-all --listen=0.0.0.0 --port=9418
"""

_ns = corev1.Namespace {
    metadata.name = _namespace
}

_deployment = appsv1.Deployment {
    metadata = {
        name = "git"
        namespace = _namespace
        labels = _labels
    }
    spec = {
        replicas = 1
        selector.matchLabels = _labels
        strategy.type = "Recreate"
        template = {
            metadata.labels = _labels
            spec = {
                hostNetwork = True
                dnsPolicy = "ClusterFirstWithHostNet"
                containers = [{
                    name = "git-daemon"
                    image = "alpine/git:latest"
                    command = ["sh", "-c", _daemonScript]
                    ports = [{
                        name = "git"
                        containerPort = 9418
                        hostPort = 9418
                    }]
                    readinessProbe = {
                        tcpSocket.port = 9418
                        initialDelaySeconds = 2
                        periodSeconds = 5
                    }
                    resources = {
                        requests = {cpu = "10m", memory = "16Mi"}
                        limits = {cpu = "250m", memory = "64Mi"}
                    }
                    volumeMounts = [{
                        name = "repo"
                        mountPath = "/srv/git"
                    }]
                }]
                volumes = [{
                    name = "repo"
                    emptyDir = {}
                }]
            }
        }
    }
}

# Namespace first so a single `kubectl apply -f -` creates it before the Deployment.
manifests.yaml_stream([_ns, _deployment])
