resource "libvirt_volume" "vm_ot_disk" {
  name           = "vm-ot.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = 10737418240 # 10 Go
}

resource "libvirt_cloudinit_disk" "vm_ot_cloudinit" {
  name           = "vm-ot-cloudinit.iso"
  user_data      = file("${path.module}/cloud_init_vm_ot.cfg")
  network_config = file("${path.module}/network_config_vm_ot.cfg")
  pool           = "default"
}

resource "libvirt_domain" "vm_ot" {
  name   = "vm-ot"
  memory = "1024"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.vm_ot_cloudinit.id

  disk {
    volume_id = libvirt_volume.vm_ot_disk.id
  }

  network_interface {
    network_id = libvirt_network.net_ot.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}