#!/bin/bash

vg=VolGroup00
sysvguuid=$(uuidgen)

if [ -d /dev/${vg} ] ; then
  echo "renaming system vg to avoid new system conflict"
  vgrename ${vg} ${sysvguuid}
  #printf 'SYSVG=\'%s\'' "${sysvguuid}" >> STATE
fi

# meander through sysfs to find a disk with no partitions that is r/w.
for d in /sys/class/block/[vsx]d[a-z] ; do
  cdisk=$(basename $d)
  # read-only check - don't stop the loop, but restart it
  read ro < /sys/class/block/${cdisk}/ro
  if [ ${ro} != 0 ] ; then
    continue
  fi
  # partition check - done by checking if wildcard resolves to a existing object
  partitions=0
  for p in /sys/class/block/${cdisk}[0-9]* ; do
    if [ -e ${p} ] ; then
      partitions=1
      break
    fi
  done
  if [ ${partitions} == 0 ] ; then
    disk=${cdisk}
    break
  fi
done

if [ -z "${disk}" ] ; then
  echo "no unpartitioned disks found, aborting" 1>&2
  exit 1
fi

echo "partitioning on ${disk}."

parted /dev/${disk} mklabel msdos
parted /dev/${disk} mkpart '' pri ext2 1m 768m
parted /dev/${disk} mkpart '' pri ext2 768m 100%

# LVM init on ${disk} - creating ${vg}
pvcreate /dev/${disk}2
vgcreate ${vg} /dev/${disk}2
lvcreate -nLogVol01 -L2G ${vg}
lvcreate -nLogVol00 -l100%FREE ${vg}

# mkfs
mkfs.xfs /dev/${disk}1
mkfs.xfs /dev/${vg}/LogVol00
mkswap /dev/${vg}/LogVol01

# mount
mkdir -p /mnt/sysimage
mount /dev/${vg}/LogVol00 /mnt/sysimage
mkdir -p /mnt/sysimage/boot
mount /dev/${disk}1 /mnt/sysimage/boot

# mounts for chroot operation
mkdir /mnt/sysimage/{sys,proc,run,dev,etc}

mount -o ro,bind /sys /mnt/sysimage/sys
mount -o ro,bind /proc /mnt/sysimage/proc
mount -t tmpfs tmpfs /mnt/sysimage/run
mount -o ro,bind /dev /mnt/sysimage/dev

# steal cmdline in case something tries to read it
printf 'BOOT_IMAGE=/vmlinuz-3.10.0-514.el7.x86_64 root=/dev/mapper/VolGroup00-LogVol00 ro crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 LANG=en_US.UTF-8' > CMDLINE
mount -o bind $(pwd)/CMDLINE /mnt/sysimage/proc/cmdline

# make an fstab
bootuuid=$(blkid /dev/vdb1 -s UUID|cut -d= -f2|sed 's/"//g')
printf '/dev/mapper/VolGroup00-LogVol00\t/\txfs\tdefaults\t0 0\n' > /mnt/sysimage/etc/fstab
printf 'UUID=%s\t/boot\txfs\tdefaults\t0 0\n' "${bootuuid}" >> /mnt/sysimage/etc/fstab
printf '/dev/mapper/VolGroup00-LogVol01\tswap\tswap\tdefaults\t0 0\n' >> /mnt/sysimage/etc/fstab
