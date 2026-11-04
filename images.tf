# Image de base Alpine Linux
resource "libvirt_volume" "alpine_base" {
  name   = "alpine-standard-cloud.qcow2"
  pool   = "default"
  source = "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/cloud/generic_alpine-3.24.1-x86_64-bios-cloudinit-r0.qcow2"
  format = "qcow2"
}

# Image de base Ubuntu Noble
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-noble-cloud.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Image de base Rocky Linux 9 GenericCloud
resource "libvirt_volume" "rocky_base" {
  name   = "rocky-9-cloud.qcow2"
  pool   = "default"
  source = "https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
  format = "qcow2"
}