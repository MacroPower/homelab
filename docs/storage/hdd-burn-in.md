# HDD Burn-in Testing

## SMART

SMART tests are run in the background. One disk cannot run multiple tests simultaneously, you must wait for them to complete before starting a new test.

```bash
mkdir -p /tmp/hddtest

for drive in sda sdb sdc sdd sde sdf sdg sdh sdi sdj; do
  smartctl -t short /dev/$drive
done

# WAIT FOR COMPLETION

for drive in sda sdb sdc sdd sde sdf sdg sdh sdi sdj; do
  smartctl -t conveyance /dev/$drive
done

# WAIT FOR COMPLETION

for drive in sda sdb sdc sdd sde sdf sdg sdh sdi sdj; do
  smartctl -t long /dev/$drive
done
```

View the results:

```bash
for drive in sda sdb sdc sdd sde sdf sdg sdh sdi sdj; do
  echo
  echo "Results for $drive:"
  echo
  smartctl -A /dev/$drive | grep -E 'Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable'
done
```

Check `Reallocated_Sector_Ct`, `Current_Pending_Sector`, and `Offline_Uncorrectable`. These should have `RAW_VALUE = 0`.

Note that Seagate drives will show a high `Raw_Read_Error_Rate` and `Seek_Error_Rate`. This is normal.

## Badblocks

:warning: This will destroy all data on the drive.

`-b` should be set to the drive's block size:

```sh
lsblk -o NAME,PHY-SeC
```

Unfortunately that will not work for larger drives. It has been alledged online that using a _multiple_ of the drive's block size is also okay, maybe. I used 16384 (4096*4).

```bash
#!/bin/bash

mkdir -p /tmp/hddtest

for drive in sda sdb sdc sdd sde sdf sdg sdh sdi sdj; do
  { badblocks -b 16384 -ws /dev/$drive 2>&1 | tee -a /tmp/hddtest/badblocks-$drive.log ; echo "$drive complete" ; } &
done
wait
echo "badblocks complete!"
```
