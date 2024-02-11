for n in knode13 knode14 knode15; do
  node=${n}.home.macro.network
  eval $(doppler run -p talhelper -c main -- talhelper gencommand upgrade -n ${node})
  sleep 120
done

for n in knode01 knode02 knode03; do
  node=${n}.home.macro.network
  sleep 120
  eval $(doppler run -p talhelper -c main -- talhelper gencommand upgrade -n ${node})
done
