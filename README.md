# manila-toolbox

Here I keep some tools for working with upstream Manila and upstream manila-csi plugin using a libvirt qemu/kvm Ubuntu guest VM running on a Fedora 33 host.

## Goal

I prefer using Fedora as a development environment but upstream Manila usses Ubuntu Focal Fossa for CI testing so it is helpful to
have a devstack environment running Ubuntu Focal Fossa where the devstack code itself and the code under development live on the Fedora
host and are exposed to the guest VM via a virtio-fs mount.  Similarly, I am using KIND (Kubenetes in Docker) as a very lightweight multinode
Kubernetes environment in which I can deploy Manila-CSI, and keeping a docker environment (rather than podman) running in Fedora is a bit of a pain.
So I run kind and manila-csi on the same Ubuntu guest VM where devstack is running, and configure it to use that devstack as its OpenStack cloud.
Reviews and edits for Manila-CSI code are done to the code under /opt/go, which really lives on the Fedora host and can be edited and updated there but
is exposed via virtiofs to the Ubuntu guest where the code is executed.

I like to use VS Code for editing and since I can do that from the host machine it doesn't need to be installed on the guest.  SSH keys for gerrit
and github aren't required on the guest.  This is handy because the guest setup itself is automated and fast.  If the guest gets corrupted (and with devstack
running at the tip of developement branches it will from time to time) it's easy to destroy and rebuild it.  Code under development won't be destroyed since
it really lives on the host.  The guest is disposable.

I expose /opt/go on the host to /opt/go on the guest and /opt/stack on the host to /opt/stack on the guest but it would be easy to modify this
setup to expose other mounts.

Soon it will be possible to use other hosts than Fedora 33 but to my knowledge at inception time for this git repo this is the only distribution with
current enough libvirt client software to support the virsh-xml commands that I need to set up the libvirt domain definition for the guest which required
for the virtio-fs mounts.

I'm starting to work on virtio-fs support for Manila remote mounts in Nova, so using a development environment that makes use of the virtio-fs and the
emerging support for it in libvirt and qemu/kvm is helpful for developing familiarity and competence with the same technologies that we want to use from
Nova itself.

The guest VM is set up with a non-root user with the same UID/GID as the
user on the host setting it up.  This makes it straightforward to edit
files on the host and execute them on the guest (or tweak them there)
without running into permission issues.

## VM Setup

  * _setup_the_guest.sh_  uses libvirt client and other VM maanagement
    commands to fetch an ubuntu cloud image, resize it, edit its domain
    definition for the mounts mentioned above.  The host machine is set
    up with /opt/stack and /opt/go and corresponding virtiofsd processes
    are set up to service these.

  * _cleanup_the_guest.sh_ is the inverse of _setup_the_guest.sh_

  * _get-ip.sh_ prints the IP at which you can ssh to the guest VM.
