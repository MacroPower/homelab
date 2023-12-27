for n in knode13 knode14 knode15; do
  node=${n}.home.macro.network
  talosctl reset --graceful=false --reboot \
    -e ${node} -n ${node} \
    --wipe-mode system-disk \
    --system-labels-to-wipe STATE \
    --system-labels-to-wipe EPHEMERAL
done

sleep 10

for n in knode01 knode02 knode03; do
  node=${n}.home.macro.network
  talosctl reset --graceful=false --reboot \
    -e ${node} -n ${node} \
    --wipe-mode system-disk \
    --system-labels-to-wipe STATE \
    --system-labels-to-wipe EPHEMERAL
done
