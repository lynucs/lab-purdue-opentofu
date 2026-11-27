
# port mirroring (manual)
## 1. Get the interface name
```bash
$ virsh net-info idmz
Name:           idmz
UUID:           dbeb37be-3d49-4399-a915-be9488e70f2c
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr2

$ virsh domiflist suricata
 Interface   Type      Source   Model    MAC
------------------------------------------------------------
 vnet5       network   ot       virtio   52:54:00:f6:5a:e2
 vnet10      network   idmz     virtio   52:54:00:4a:a6:4a

```

## 2. Force the flooding on the iDMZ bridge
sudo ip link set dev virbr2 type bridge ageing_time 0

## 3. Configure the new interface 
sudo ip link set dev vnet10 promisc on
sudo bridge link set dev vnet10 flood on

## 4. Check ont the suricata VM
sudo tcpdump -nni eth1 -c 5

# port mirroring (Automatisation)
**sans automatisation**, il faut refaire ces commandes à chaque démarrage de `suricata` ou du réseau `idmz` (car `vnet10` est un numéro dynamique recréé à chaque boot de la VM).

Vous pouvez rendre ce port mirroring **100 % automatique et persistant** sur l'hôte `laurent-MS-A2` en utilisant le mécanisme natif des **hooks libvirt** (`/etc/libvirt/hooks/qemu` et `/etc/libvirt/hooks/network`), sans dépendre du nom dynamique `vnetX`.

1. **Créer le hook libvirt pour le bridge et l'interface de capture:** 2 min — Sur laurent-MS-A2.
Créez le répertoire des hooks libvirt et le script `/etc/libvirt/hooks/qemu` qui détecte automatiquement le bridge et l'interface `vnet*` de `suricata` sur le réseau `idmz` à chaque démarrage de la VM :

```bash
sudo mkdir -p /etc/libvirt/hooks
sudo tee /etc/libvirt/hooks/qemu > /dev/null <<'EOF'
#!/bin/bash
VM_NAME="$1"
EVENT="$2"
SUBEVENT="$3"

if [ "$VM_NAME" = "suricata" ] && { [ "$EVENT" = "started" ] || [ "$EVENT" = "reconnect" ]; }; then
    BRIDGE=$(virsh net-info idmz | awk '/^Bridge:/ {print $2}')
    VNET=$(virsh domiflist suricata | awk '$3 == "idmz" {print $1}')

    if [ -n "$BRIDGE" ]; then
        ip link set dev "$BRIDGE" type bridge ageing_time 0
    fi

    if [ -n "$VNET" ]; then
        ip link set dev "$VNET" promisc on
        bridge link set dev "$VNET" flood on
    fi
fi
EOF
sudo chmod +x /etc/libvirt/hooks/qemu

```

*Verification:* `ls -l /etc/libvirt/hooks/qemu` affiche les permissions `-rwxr-xr-x` et aucun chemin codé en dur (`virbr2` et `vnet*` sont résolus dynamiquement).


2. **Recharger le démon libvirtd pour activer le hook:** 1 min — Sur laurent-MS-A2.
Sur Ubuntu, rechargez ou redémarrez `libvirtd` (cela n'arrête pas vos VMs en cours d'exécution) afin qu'il prenne en compte le nouveau hook :

```bash
sudo systemctl reload-or-restart libvirtd

```

*Verification:* `sudo systemctl is-active libvirtd` retourne `active`.


3. **Tester la persistance au redémarrage de la VM suricata:** 2 min — Sur laurent-MS-A2 et suricata.
Redémarrez `suricata` et vérifiez immédiatement sur l'hôte que le bridge et la nouvelle interface `vnet*` ont reçu les paramètres `ageing_time 0`, `promisc` et `flood on` :

```bash
virsh reboot suricata && sleep 15
BRIDGE=$(virsh net-info idmz | awk '/^Bridge:/ {print $2}')
VNET=$(virsh domiflist suricata | awk '$3 == "idmz" {print $1}')
ip -d link show "$BRIDGE" | grep -o "ageing_time [0-9]*"
ip -d link show "$VNET" | grep -o "PROMISC"
bridge -d link show dev "$VNET" | grep -o "flood on"

```

*Verification:* Les trois commandes retournent respectivement `ageing_time 0`, `PROMISC` et `flood on`, et `ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.50 "sudo tcpdump -nni eth1 -c 5"` capture le trafic iDMZ sans aucune action manuelle.


*(Alternative OpenTofu/libvirt : si vous voulez figer le nom de l'interface côté hôte dans `vm_suricata.tf`, vous pouvez aussi ajouter `<target dev="vnet-suricata-idmz"/>` via `xslt` ou rester sur ce hook qui fonctionne quelle que soit la numérotation `vnetX` attribuée par le noyau.)*