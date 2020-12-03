#!/bin/bash

VM=ubuntu-focal
IMG=focal-server-cloudimg-amd64.img
BASEDIR=/var/lib/libvirt/images/base
BASEIMG=$BASEDIR/ubuntu-focal.qcow2
INSTDIR=/var/lib/libvirt/images/instance-1

sudo virsh destroy $VM 2>/dev/null || true
sudo virsh undefine $VM 2> /dev/null || true
sudo rm -rf $INSTDIR
sudo rm -rf $BASEIMG
#rm -f ~/Images/$IMG

sudo pkill virtiofsd


