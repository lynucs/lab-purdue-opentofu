# Réseau IT : routé vers l'hôte
resource "libvirt_network" "net_it" {
  name      = "it"
  mode      = "route"
  domain    = "it.local"
  addresses = ["192.168.10.0/24"]
  autostart = true

  dns {
    enabled = true
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