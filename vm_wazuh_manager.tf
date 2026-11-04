# 1. Image disque de base (QCOW2 Rocky Linux 9)
resource "libvirt_volume" "wazuh_disk" {
  name             = "wazuh_manager.qcow2"
  base_volume_name = "Rocky-9-GenericCloud.qcow2"
  pool             = "default"
  size             = 42949672960 # 40 Go (taille en octets pour accueillir l'indexeur et les logs)
}

resource "libvirt_cloudinit_disk" "wazuh_cloudinit" {
  name      = "wazuh_cloudinit.iso"
  user_data = templatefile("${path.module}/cloud_init_wazuh.cfg", {})
  pool      = "default"
}

# 3. Domaine Libvirt / VM
resource "libvirt_domain" "wazuh_manager" {
  name   = "wazuh-manager"
  memory = 4096 # 8 Go recommandés pour Wazuh All-in-One (ou 4096 au strict minimum)
  type   = "kvm"
  vcpu   = 4

  # Activation du jeu d'instructions du processeur hôte (x86-64-v2 / v3)
  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.wazuh_cloudinit.id

  # Interface rattachée au réseau OT (virbr3)
  network_interface {
    network_name   = "ot" # Référence au réseau Libvirt 'ot' qui porte virbr3
    wait_for_lease = false
    mac            = "52:54:00:19:30:64" # Adresse MAC fixe optionnelle (ex: .30.100)
  }

  disk {
    volume_id = libvirt_volume.wazuh_disk.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

output "wazuh_manager_ip" {
  description = "Adresse IP statique du Wazuh Manager"
  value       = "192.168.30.100"
}