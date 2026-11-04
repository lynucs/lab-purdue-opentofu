ansible/
├── inventory.ini
├── deploy_purdue_rules.yaml
└── templates/
    └── purdue_ot.rules.j2


# port mirroring

laurent@laurent-MS-A2:~$ virsh domiflist suricata
 Interface   Type      Source   Model    MAC
------------------------------------------------------------
 vnet3       network   ot       virtio   52:54:00:f6:5a:e2
 vnet5       network   idmz     virtio   52:54:00:4a:a6:4a

laurent@laurent-MS-A2:~$ virsh net-info idmz
Name:           idmz
UUID:           dbeb37be-3d49-4399-a915-be9488e70f2c
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr2

Exécutez sur votre machine hôte (laurent-MS-A2) les commandes en ciblant vnet5 :

# 1. Forcer le flooding sur le bridge iDMZ
sudo ip link set dev virbr2 type bridge ageing_time 0

# 2. Configurer la nouvelle interface hôte de Suricata (vnet5)
sudo ip link set dev vnet5 promisc on
sudo bridge link set dev vnet5 flood on

Contrôlez ensuite dans la VM suricata :
sudo tcpdump -nni eth1 -c 5


###
Le moteur Suricata 7.0.17 tourne en mode IDS, avec 53 307 règles chargées, et l'interface de capture passive (`eth1` / `ens4`) a bien ses offloadings coupés et le flag `PROMISC` actif.

Deux éléments méritent attention :

1. **Liaison af-packet sur `ens4` :** Suricata s'est lié sur l'altname `ens4`, ce qui fonctionne nativement grâce au support des noms alternatifs par le noyau Linux.
2. **Avertissement de performance :** `Warning: af-packet: ens4: AF_PACKET tpacket-v3 is recommended for non-inline operation`. En mode passif (TAP/SPAN), passer Suricata en `tpacket-v3` permet un traitement par blocs plutôt que paquet par paquet, réduisant l'overhead CPU.

---

### Test de détection IDS en direct

Pour vérifier que la chaîne de détection fonctionne de bout en bout et génère des alertes dans `/var/log/suricata/fast.log` et `/var/log/suricata/eve.json` :

#### 1. Suivre les journaux d'alerte dans la VM `suricata`

Dans votre console sur la VM :

```bash
sudo tail -f /var/log/suricata/fast.log

```

#### 2. Générer une trame de test depuis une autre machine du LAB

Depuis `vm-it` (ou toute machine pouvant injecter du trafic sur le réseau supervisé par l'iDMZ), exécutez la requête HTTP standard de test de règles IDS/IPS (signature ET INFO test rule) :

```bash
curl -A "blackhat" http://testmyids.com

```

*Alternative via netcat / socat si vous n'avez pas de connectivité Internet sortante :*

```bash
# Envoyer une signature de test standard dans un flux traversant l'iDMZ
echo "GET /testmyids HTTP/1.1" | nc -w 1 192.168.20.1 80

```

#### 3. Résultat attendu dans `/var/log/suricata/fast.log`

Une entrée semblable à celle-ci doit s'inscrire immédiatement :

```text
[**] [1:2100498:7] GPL ATTACK_RESPONSE id check returned root [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} ...

```

---

### Optimisation : Passer en `tpacket-v3` (Optionnel)

Pour éliminer l'avertissement dans les logs de Suricata et optimiser la capture passive, dans `/etc/suricata/suricata.yaml` (ou dans votre template Ansible `suricata.yaml.j2`) :

```yaml
af-packet:
  - interface: eth1   # ou ens4
    threads: auto
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
    tpacket-v3: yes

```

Puis rechargez Suricata :

```bash
sudo systemctl restart suricata

```

---

### Vérification de l'agent Wazuh (si inclus dans le playbook)

Si la partie agent Wazuh a été déployée en fin de playbook :

```bash
sudo systemctl status wazuh-agent
sudo /var/ossec/bin/agent-auth -m <ip_manager>  # si non enregistré
sudo grep -i "suricata" /var/ossec/etc/ossec.conf

```

L'agent doit ingérer `/var/log/suricata/eve.json` au format `json` pour remonter les alertes directement dans le SIEM/SOC.