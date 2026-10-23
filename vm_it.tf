resource "libvirt_volume" "vm_it_disk" {
  name           = "vm-it.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = 10737418240 # 10 Go
}

resource "libvirt_cloudinit_disk" "vm_it_cloudinit" {
  name           = "vm-it-cloudinit.iso"
  user_data      = file("${path.module}/cloud_init_vm_it.cfg")
  network_config = file("${path.module}/network_config_vm_it.cfg")
  pool           = "default"
}

resource "libvirt_domain" "vm_it" {
  name   = "vm-it"
  memory = "1024"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.vm_it_cloudinit.id

  disk {
    volume_id = libvirt_volume.vm_it_disk.id
  }

  network_interface {
    network_id = libvirt_network.net_it.id
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