doppler run -p talhelper -c main -- talhelper validate talconfig

doppler run -p talhelper -c main -- talhelper genconfig --no-gitignore
talosctl --talosconfig=./clusterconfig/talosconfig config endpoint \
    https://knode01.home.macro.network:6443 \
    https://knode02.home.macro.network:6443 \
    https://knode03.home.macro.network:6443

eval $(doppler run -p talhelper -c main -- talhelper gencommand apply)
