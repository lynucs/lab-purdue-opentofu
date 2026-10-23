
# Virsh
virsh net-list --all
virsh list --all

virsh domifaddr win2022
virt-viewer win2022

sudo virsh net-start lab-net
sudo virsh net-autostart lab-net
virsh net-list --all

virsh console vm-it
virsh console vm-idmz
virsh console vm-ot
virsh console fw1
virsh console fw2

# Schéma d'adressage retenu

Machine     Réseau      IP / Masque         Passerelle par défautRoute statique (vers OT 192.168.30.0/24)
vm-it       it          192.168.10.10/24    192.168.10.1 (Hôte NAT)Via 192.168.10.254 (fw1) pour joindre iDMZ/OT
vm-idmz     idmz        192.168.20.10/24    192.168.20.254 (fw1)Via 192.168.20.253 (fw2)
vm-ot       ot          192.168.30.10/24    192.168.30.254 (fw2)Aucune (tout passe par fw2)

Acces au machines depuis le host
=======================================
sudo ip route add 192.168.20.0/24 via 192.168.10.254
sudo ip route add 192.168.30.0/24 via 192.168.10.254

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.10   # vm-it
ssh -i ~/.ssh/id_ed25519 alpine@192.168.10.254  # fw1
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.20.10   # vm-idmz
ssh -i ~/.ssh/id_ed25519 alpine@192.168.20.254  # fw2
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.30.10   # vm-ot

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.10 "ping -c 2 192.168.20.10"
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.10 "ping -c 2 192.168.30.10"
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.20.10 "ping -c 2 192.168.30.10"

# Remancer une machine
==========================
tofu apply   -replace="libvirt_domain.fw1"   -replace="libvirt_cloudinit_disk.fw1_cloudinit"   -replace="libvirt_volume.fw1_disk"
tofu apply   -replace="libvirt_domain.fw2"   -replace="libvirt_cloudinit_disk.fw2_cloudinit"   -replace="libvirt_volume.fw2_disk"

# Pour sortir sur internet - command à entrer sur le host:
## 1. Identifier l'interface WAN
$ ip route get 8.8.8.8
8.8.8.8 via 192.168.1.254 dev enp3s0 src 192.168.1.100 uid 1000 

## 2. Activer le forwarding IP sur l'hôte
sudo sysctl -w net.ipv4.ip_forward=1

## 3. Ajouter la règle de masquerade pour le sous-réseau IT
sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o enp3s0 -j MASQUERADE

# optionnel
Nettoyage de l'IP parasite Link-Local (169.254.x.x) sur fw2Sur fw2, on observe l'adresse 169.254.197.1/16 générée par le démon IPv4LL/dhcpcd. Pour éliminer cette route parasite et la métrique redondante :Sur fw2, supprimez l'adresse à chaud si souhaité :Bashsudo ip addr del 169.254.197.1/16 dev eth0
Dans cloud_init_fw2.cfg, ajouter noipv4ll dans /etc/dhcpcd.conf ou s'assurer que dhcpcd ne démarre pas sur eth0 supprime définitivement ce bail local.   




# Prochaine étape : Implémenter le filtrage IEC 62443 / Purdue
Maintenant que le routage de niveau 3 est validé de bout en bout, les deux pare-feux transfèrent actuellement tout le trafic sans restriction.

Pour verrouiller l'architecture selon la norme :

Sur fw1 : Interdire l'accès direct depuis la zone IT (192.168.10.0/24) vers la zone OT (192.168.30.0/24), et forcer le passage par un serveur relais / bastion dans l'iDMZ (vm-idmz sur 192.168.20.10).

Sur fw2 : N'autoriser les flux vers l'OT (192.168.30.0/24) que s'ils proviennent strictement de l'iDMZ (192.168.20.0/24).

OT ?" query="Comment configurer iptables sur fw1 et fw2 pour appliquer la segmentation Purdue interdisant le passage direct IT -> OT ?" />

# https://github.com/lynucs/lab-purdue-opentofu
git config --global user.email "mail@laurentferon.com"
git config --global user.name "Laurent Feron"
git commit -m "feat: lab complet IT/IDMZ/OT avec KVM, OpenTofu, firewalls Alpine et hôtes Ubuntu"
git branch -M main
git remote add origin git@github.com:lynucs/lab-purdue-opentofu.git
git push -u origin main
