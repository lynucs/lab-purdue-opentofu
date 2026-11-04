# Disque OS dérivé de Rocky Linux 9
resource "libvirt_volume" "vm_suricata_disk" {
  name           = "vm-suricata.qcow2"
  base_volume_id = libvirt_volume.rocky_base.id
  pool           = "default"
  size           = 26843545600 # 25 Go
}

# Image Cloud-Init
resource "libvirt_cloudinit_disk" "vm_suricata_cloudinit" {
  name           = "vm-suricata-cloudinit.iso"
  user_data      = file("${path.module}/cloud_init_vm_suricata.cfg")
  # network_config = file("${path.module}/network_config_vm_suricata.cfg")
  pool           = "default"
}

# VM Suricata sous Rocky Linux
resource "libvirt_domain" "vm_suricata" {
  name   = "suricata"
  type   = "kvm"
  memory = "4096"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.vm_suricata_cloudinit.id

  # Activation du jeu d'instructions du processeur hôte (x86-64-v2 / v3)
  cpu {
    mode = "host-passthrough"
  }


  disk {
    volume_id = libvirt_volume.vm_suricata_disk.id
  }


  # ens3 : Réseau OT (Administration)
  network_interface {
    network_id     = libvirt_network.net_ot.id
    wait_for_lease = false
  }

  # ens4 : Réseau iDMZ (Capture / SPAN)
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