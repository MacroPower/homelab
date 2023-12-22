# v1 to v2 Upgrade

1. Insert an SD card into the Turing Pi 2.
2. Download the latest [Turing Pi 2 image](https://firmware.turingpi.com/turing-pi2/).
3. Flash the image to the SD card.
```sh
set HOST "10.0.130.62"
ssh root@$HOST umount /mnt/sdcard
ssh root@$HOST dd of=/dev/mmcblk0 bs=1M < ~/Downloads/tp2-firmware-sdcard-v2.0.5.img
ssh root@$HOST reboot
```
4. Wait until all LAN LEDs are blinking slowly in unison (1 sec on, 1 sec off).
5. Press KEY1 on the board rapidly 3 times
6. Wait until all LAN LEDs are blinking 2x rapidly in unison (0.1 sec on, 0.1 sec off, 0.1 sec on, 1 sec off).
7. Disconnect Power
8. Reconnect Power
9. AFTER power has been connected, immediately press and hold KEY1 on the board for 5 seconds. Ensure you do not hold the button for too much longer than 5 seconds, as you can enter failsafe boot.
10. Delete the SD card contents and reboot.
```sh
set HOST "10.0.180.99"
ssh root@$HOST dd if=/dev/zero of=/dev/mmcblk0 count=4096
ssh root@$HOST reboot
```
