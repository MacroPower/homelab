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
talosctl dashboard -n $NODE.home.macro.network

# Check node health
talosctl health -n $NODE.home.macro.network

# Get a support bundle (logs from kubelet, etcd, etc.)
talosctl support -n $NODE.home.macro.network
unzip support.zip && rm support.zip
# Cleanup
rm -rf $NODE.home.macro.network/ cluster/

# Reboot a node
talosctl reboot -n $NODE.home.macro.network

# Reset a node
talosctl reset -n $NODE.home.macro.network \
    --graceful=true --reboot \
    --wipe-mode system-disk \
    --system-labels-to-wipe STATE \
    --system-labels-to-wipe EPHEMERAL
```
