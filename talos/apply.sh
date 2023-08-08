doppler run -p talhelper -c main talhelper genconfig

talosctl apply-config -e kube.home.macro.network -n knode01.home.macro.network -f clusterconfig/home-knode01.home.macro.network.yaml
talosctl apply-config -e kube.home.macro.network -n knode02.home.macro.network -f clusterconfig/home-knode02.home.macro.network.yaml
talosctl apply-config -e kube.home.macro.network -n knode03.home.macro.network -f clusterconfig/home-knode03.home.macro.network.yaml
talosctl apply-config -e kube.home.macro.network -n knode13.home.macro.network -f clusterconfig/home-knode13.home.macro.network.yaml
talosctl apply-config -e kube.home.macro.network -n knode14.home.macro.network -f clusterconfig/home-knode14.home.macro.network.yaml
talosctl apply-config -e kube.home.macro.network -n knode15.home.macro.network -f clusterconfig/home-knode15.home.macro.network.yaml
