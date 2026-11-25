# Disque OS dérivé de Rocky Linux 9
resource "libvirt_volume" "vm_squid_disk" {
  name           = "vm-squid.qcow2"
  base_volume_id = libvirt_volume.rocky_base.id
  pool           = "default"
  size           = 21474836480 # 20 Go
}

# Image Cloud-Init
resource "libvirt_cloudinit_disk" "vm_squid_cloudinit" {
  name      = "vm-squid-cloudinit.iso"
  user_data = file("${path.module}/cloud_init_vm_squid.cfg")
  pool      = "default"
}

# VM Squid sous Rocky Linux
resource "libvirt_domain" "vm_squid" {
  name   = "squid"
  type   = "kvm"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.vm_squid_cloudinit.id

  # Activation du jeu d'instructions du processeur hôte (x86-64-v2 / v3)
  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.vm_squid_disk.id
  }

  # eth0 : Réseau iDMZ
  network_interface {
    network_id     = libvirt_network.net_idmz.id
    wait_for_lease = false
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