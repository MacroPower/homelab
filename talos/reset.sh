talosctl reset --graceful=false --reboot -e knode13.home.macro.network -n knode13.home.macro.network
talosctl reset --graceful=false --reboot -e knode14.home.macro.network -n knode14.home.macro.network
talosctl reset --graceful=false --reboot -e knode15.home.macro.network -n knode15.home.macro.network

sleep 10

talosctl reset --graceful=false --reboot -e knode01.home.macro.network -n knode01.home.macro.network
talosctl reset --graceful=false --reboot -e knode02.home.macro.network -n knode02.home.macro.network
talosctl reset --graceful=false --reboot -e knode03.home.macro.network -n knode03.home.macro.network
