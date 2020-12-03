#!/bin/bash
set -u
set -e
# set -x
set -o pipefail

IMG=focal-server-cloudimg-amd64.img
BASEDIR=/var/lib/libvirt/images/base
BASEIMG=$BASEDIR/ubuntu-focal.qcow2
INSTDIR=/var/lib/libvirt/images/instance-1
INSTIMG=$INSTDIR/instance-1.qcow2
ISO=$INSTDIR/instance1-cidata.iso
URL=https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

METADATA=/tmp/meta-data
USERDATA=/tmp/user-data
PUBKEYFILE=$HOME/.ssh/id_rsa.pub
PUBKEY=$(cat $PUBKEYFILE)

if [ ! -f $PUBKEYFILE ]; then
   echo "No ssh key set up for user $USER!"
   echo "Pleae run `ssh-keygen` and then re-run this script."
   exit -1
fi

sudo mkdir -p /opt/stack; sudo chmod 777 /opt/stack
sudo mkdir -p /opt/go; sudo chmod 777 /opt/go

sudo /usr/libexec/virtiofsd --socket-path=/var/run/virtiofs1 -o source=/opt/stack -o cache=always &
sudo /usr/libexec/virtiofsd --socket-path=/var/run/virtiofs2 -o source=/opt/go -o cache=always &

cat <<EOF >$METADATA
local-hostname: ubuntu-1
EOF

cat <<EOF >$USERDATA
#cloud-config
bootcmd:
  - mkdir -p /opt/stack
  - mkdir -p /opt/go

mounts:
 - [ stack, /opt/stack, virtiofs, "defaults,nofail", "0", "0" ]
 - [ go, /opt/go, virtiofs, "defaults,nofail", "0", "0" ]

users:
  - name: $USER
    ssh-authorized-keys:
      - $PUBKEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
    uid: "$UID"

EOF

sudo mkdir -p $BASEDIR
if [ ! -f $BASEIMG ]; then
  mkdir -p ~/Images
  pushd ~/Images
  if [ ! -f $IMG ] ; then
    wget $URL
  fi
  sudo cp $IMG $BASEIMG
  popd
fi
sudo mkdir -p $INSTDIR
sudo qemu-img create -f qcow2 -F qcow2 -o backing_file=$BASEIMG $INSTIMG
sudo qemu-img resize $INSTIMG 20G
pushd /tmp
sudo genisoimage -output $ISO -volid cidata -joliet -rock $USERDATA $METADATA
popd

sudo virt-install --connect qemu:///system \
	--virt-type="kvm"\
	--name="ubuntu-focal"\
	--ram=16384\
	--vcpus=4\
	--os-type="linux"\
	--os-variant="ubuntu20.04"\
	--disk path=$INSTIMG,format="qcow2"\
        --disk path=$ISO,device=cdrom\
	--import\
	--network network=default,model=virtio\
	--noautoconsole

sudo virsh list
sudo virsh dumpxml ubuntu-focal > /tmp/ubuntu-focal.xml

sudo virsh setmaxmem --config  ubuntu-focal 16777216
sudo virt-xml ubuntu-focal --edit --memorybacking="access.mode=shared"
sudo virt-xml ubuntu-focal --edit --cpu mode='host-model,numa.cell0.id="0",numa.cell0.cpus="0-3",numa.cell0.memory="16777216",numa.cell0.memAccess="shared"'
sudo virt-xml ubuntu-focal --add-device --filesystem "type='mount',accessmode='passthrough',driver.type='virtiofs',source.dir='/opt/stack',target.dir='stack'"
sudo virt-xml ubuntu-focal --add-device --filesystem "type='mount',accessmode='passthrough',driver.type='virtiofs',source.dir='/opt/go',target.dir='go'"

sudo virsh destroy ubuntu-focal

sudo virsh start ubuntu-focal
sudo virsh dumpxml ubuntu-focal > /tmp/ubuntu-focal-with-virtio.xml

./get-ip.sh

