# Laboratoire Virtuel IEC 62443 / Modèle Purdue avec OpenTofu & KVM

Ce projet déploie et configure un banc d'essai complet pour simuler une architecture réseau industrielle segmentée selon les recommandations du **modèle Purdue** et du standard de cybersécurité **IEC 62443**. 

L'infrastructure est orchestrée par **OpenTofu** sur un hyperviseur **KVM / Libvirt** local et repose sur des pare-feux légers **Alpine Linux** et des nœuds **Ubuntu 24.04 LTS**.

---

## 1. Topologie Réseau et Architecture

L'architecture segmente l'infrastructure en trois zones isolées reliées par deux barrières de filtrage :

```text
[ Hôte / LAN ]
       │
┌──────▼────────────────────────────────────────────────┐
│ Réseau IT (Niveau 4/5) : 192.168.10.0/24 (routed)     │
│   ├── vm-it           : 192.168.10.10                 │
│   └── fw1 (eth0)      : 192.168.10.254                │
└──────┬────────────────────────────────────────────────┘
       │ [ Firewall 1 - Alpine Linux ]
┌──────▼────────────────────────────────────────────────┐
│ Zone iDMZ (Niveau 3.5) : 192.168.20.0/24 (isolé)      │
│   ├── fw1 (eth1)      : 192.168.20.254                │
│   ├── vm-idmz (Relais): 192.168.20.10                 │
│   └── fw2 (eth0)      : 192.168.20.253                │
└──────┬────────────────────────────────────────────────┘
       │ [ Firewall 2 - Alpine Linux ]
┌──────▼────────────────────────────────────────────────┐
│ Zone OT (Niveau 0-3)  : 192.168.30.0/24 (isolé)       │
│   ├── fw2 (eth1)      : 192.168.30.254                │
│   └── vm-ot (Cible)   : 192.168.30.10                 │
└───────────────────────────────────────────────────────┘