resource "libvirt_volume" "ejbca_disk" {
  name           = "ejbca.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = 10737418240 # 10 Go
}

resource "libvirt_cloudinit_disk" "ejbca_cloudinit" {
  name           = "ejbca-cloudinit.iso"
  user_data      = file("${path.module}/cloud_init_ejbca.cfg")
  network_config = file("${path.module}/network_config_ejbca.cfg")
  pool           = "default"
}

resource "libvirt_domain" "ejbca" {
  name   = "ejbca"
  type   = "kvm"
  memory = "2048" # 2 Go recommandé pour EJBCA
  vcpu   = 2

  # Activation du jeu d'instructions du processeur hôte (x86-64-v2 / v3)
  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.ejbca_cloudinit.id

  disk {
    volume_id = libvirt_volume.ejbca_disk.id
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