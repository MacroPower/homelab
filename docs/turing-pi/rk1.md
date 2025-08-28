# RK1

## Talos on NVMe

First, flash ubuntu to the MMC flash. This is needed because we don't directly have access to flash the NVMe drive.

Get the latest image here: https://firmware.turingpi.com/turing-rk1/

```sh
curl -LO https://firmware.turingpi.com/turing-rk1/ubuntu_22.04_rockchip_linux/v1.33/ubuntu-22.04.3-preinstalled-server-arm64-turing-rk1_v1.33.img.xz
xz -d ubuntu-22.04.3-preinstalled-server-arm64-turing-rk1_v1.33.img.xz
task tpi:flash TPI_HOST=1 TPI_NODE=1 IMAGE_PATH=ubuntu-22.04.3-preinstalled-server-arm64-turing-rk1_v1.33.img
```

IF there is already an OS on the NVMe drive that the RK1 is booting from by default, you can interrupt the boot sequence and override this with `task turingpi:boot-target`. Below is a reduced example of the expected inputs and outputs.

```console
$ task turingpi:boot-target TPI_HOST=1 TPI_NODE=1 TARGET=mmc0
Boot turingpi01 node 1 to mmc0? [y/N] y
task: [turingpi:power] tpi power off
ok
task: [turingpi:power] tpi power on
ok
task: [turingpi:boot-target] sleep 3
task: [turingpi:uart:set] tpi uart set --cmd='a'
ok
task: [turingpi:uart:get] tpi uart get
Hit any key to stop autoboot:  0
=>
=>
task: [turingpi:uart:set] tpi uart set --cmd='setenv boot_targets "mmc0"'
ok
task: [turingpi:uart:get] tpi uart get
setenv boot_targets "mmc0"
=>
=>
Would you like to issue a boot command? [y/N] y
task: [turingpi:uart:set] tpi uart set --cmd='boot'
ok
```

Get a shell and write the Talos image to the NVMe drive.

You can get an image from <https://factory.talos.dev/>

```console
$ # First login password: ubuntu
$ ssh ubuntu@knode01.home.macro.network
WARNING: Your password has expired.
You must change your password now and login again!

$ ssh ubuntu@knode01.home.macro.network
$ curl -LO https://factory.talos.dev/image/df156b82096feda49406ac03aa44e0ace524b7efe4e1f0e144a1e1ae3930f1c0/v1.9.5/metal-arm64.raw.xz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 68.7M  100 68.7M    0     0  44.1M      0  0:00:01  0:00:01 --:--:-- 68.3M
$ xz -d metal-arm64.raw.xz
$ ls -l
total 140220
-rw-rw-r-- 1 ubuntu ubuntu 1306525696 May 28 02:42 metal-arm64.raw
$ # Be careful!
$ sudo dd if=metal-arm64.raw of=/dev/nvme0n1
2551808+0 records in
2551808+0 records out
1306525696 bytes (1.3 GB, 1.2 GiB) copied, 11.7383 s, 111 MB/s
$ exit
$ task tpi:power TPI_HOST=1 TPI_NODE=1 STATE=off
```

Finally, re-flash the MMC flash with the Talos u-boot image.

```sh
docker pull ghcr.io/nberlee/u-boot:v1.6.0-34-gbd408d3-dirty
# I pulled u-boot-rockchip-spi.bin from the image in the Orbstack UI
task tpi:flash TPI_HOST=1 TPI_NODE=1 IMAGE_PATH=u-boot-rockchip-spi.bin
```

## References

- https://github.com/nberlee/talos/blob/release-1.7-turingrk1/website/content/v1.7/talos-guides/install/single-board-computers/turing_rk1.md
- https://github.com/bguijt/turingpi2/tree/main/projects/talos/shell
- https://www.talos.dev/v1.10/talos-guides/install/single-board-computers/turing_rk1/
