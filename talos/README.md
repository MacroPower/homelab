# Talos

Generated with [talhelper](https://github.com/budimanjojo/talhelper)

## Commands

Cluster commands:

```sh
# Roll out config
./apply.sh

# Reset the cluster to a clean state (destroys everything)
./reset.sh

# Bootstrap a new cluster
./bootstrap.sh
```

Node commands:

```sh
set NODE knode01

# Open node dashboard
talosctl dashboard -e kube.home.macro.network -n $NODE.home.macro.network

# Check node health
talosctl health -e kube.home.macro.network -n $NODE.home.macro.network

# Get a support bundle (logs from kubelet, etcd, etc.)
talosctl support -e kube.home.macro.network -n $NODE.home.macro.network
unzip support.zip && rm support.zip
# Cleanup
rm -rf $NODE.home.macro.network/ cluster/

# Reboot a node
talosctl reboot -e kube.home.macro.network -n $NODE.home.macro.network

# Reset a node
talosctl reset --graceful=true --reboot -e kube.home.macro.network -n $NODE.home.macro.network
```
