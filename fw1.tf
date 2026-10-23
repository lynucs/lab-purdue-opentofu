resource "libvirt_volume" "fw1_disk" {
  name           = "fw1.qcow2"
  base_volume_id = libvirt_volume.alpine_base.id
  pool           = "default"
  size           = 2147483648 # 2 Go
}

resource "libvirt_cloudinit_disk" "fw1_cloudinit" {
  name      = "fw1-cloudinit.iso"
  user_data = file("${path.module}/cloud_init_fw1.cfg")
  pool      = "default"
}

resource "libvirt_domain" "fw1" {
  name   = "fw1"
  memory = "256"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.fw1_cloudinit.id

  disk {
    volume_id = libvirt_volume.fw1_disk.id
  }

  network_interface {
    network_id = libvirt_network.net_it.id
  }

  network_interface {
    network_id = libvirt_network.net_idmz.id
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