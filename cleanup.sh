#!/bin/bash

touch /mnt/sysimage/.autorelabel

find /mnt/sysimage/var/cache/yum/x86_64/7/*/packages -name \*.rpm -exec rm {} \;

fstrim -v /mnt/sysimage

for x in $(grep /mnt/sysimage /proc/mounts|tac|cut -d' ' -f2) ; do umount $x ; done

#vgchange -an VolGroup00
#vgexport VolGroup00

