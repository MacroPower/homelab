talosctl reset --graceful=false --reboot -e knode13.home.macro.network -n knode13.home.macro.network

sleep 10

talosctl reset --graceful=false --reboot -e knode01.home.macro.network -n knode01.home.macro.network
