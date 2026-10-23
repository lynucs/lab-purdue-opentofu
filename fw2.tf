resource "libvirt_volume" "fw2_disk" {
  name           = "fw2.qcow2"
  base_volume_id = libvirt_volume.alpine_base.id
  pool           = "default"
  size           = 2147483648 # 2 Go
}

resource "libvirt_cloudinit_disk" "fw2_cloudinit" {
  name      = "fw2-cloudinit.iso"
  user_data = file("${path.module}/cloud_init_fw2.cfg")
  pool      = "default"
}

resource "libvirt_domain" "fw2" {
  name   = "fw2"
  memory = "256"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.fw2_cloudinit.id

  disk {
    volume_id = libvirt_volume.fw2_disk.id
  }

  network_interface {
    network_id = libvirt_network.net_idmz.id
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