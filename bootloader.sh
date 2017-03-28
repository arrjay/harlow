#!/bin/bash

echo 'GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00"' > /mnt/sysimage/etc/default/grub

grub2-install --root-directory=/mnt/sysimage /dev/vdb

chroot /mnt/sysimage/ grub2-mkconfig -o /boot/grub2/grub.cfg

for x in /mnt/sysimage/boot/vmlinuz-*x86_64 ; do
  rel=$(basename $x)
  rel=${rel%vmlinuz-}
  echo $rel
done
