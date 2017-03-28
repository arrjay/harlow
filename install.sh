#!/bin/bash

rpm --root /mnt/sysimage --initdb


rpm --root /mnt/sysimage -ivh --nodeps 

scratch=$(mktemp -d)
pushd $scratch
yumdownloader centos-release
rpm --root /mnt/sysimage -ivh --nodeps centos-release*rpm
popd

yum --installroot /mnt/sysimage install -y @Base kernel rsyslog grub2-tools grub2 lvm2 selinux-policy-targeted
