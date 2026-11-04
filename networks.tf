# Réseau IT : routé vers l'hôte
resource "libvirt_network" "net_it" {
  name      = "it"
  mode      = "route"
  domain    = "it.local"
  addresses = ["192.168.10.0/24"]
  autostart = true

dns {
    enabled    = true
    local_only = false

    # Forwarders DNS amont (Cloudflare, Google, ou DNS de votre box/FAI)
    forwarders {
      address = "1.1.1.1"
    }

    forwarders {
      address = "8.8.8.8"
    }

# --- Zone IT (it.local) ---
    hosts {
      ip       = "192.168.10.10"
      hostname = "vm-it.it.local"
    }

    hosts {
      ip       = "192.168.10.254"
      hostname = "fw1.it.local"
    }

    # --- Zone iDMZ (idmz.local) ---
    hosts {
      ip       = "192.168.20.10"
      hostname = "vm-idmz.idmz.local"
    }

    hosts {
      ip       = "192.168.20.253"
      hostname = "fw1.idmz.local"
    }

    hosts {
      ip       = "192.168.20.254"
      hostname = "fw2.idmz.local"
    }

    hosts {
      ip       = "192.168.10.100"
      hostname = "ejbca.it.local"
    }

    # --- Zone OT (ot.local) ---
    hosts {
      ip       = "192.168.30.10"
      hostname = "vm-ot.ot.local"
    }

    hosts {
      ip       = "192.168.30.253"
      hostname = "fw2.ot.local"
    }
    # --- Sonde IDS (ot.local) ---
    hosts {
      ip       = "192.168.30.50"
      hostname = "suricata.ot.local"
    }
  }
}

# Réseau iDMZ : isolé
resource "libvirt_network" "net_idmz" {
  name      = "idmz"
  mode      = "none"
  autostart = true
}

# Réseau OT : isolé
resource "libvirt_network" "net_ot" {
  name      = "ot"
  mode      = "none"
  autostart = true
}