# Access to the machine
```bash
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.50
```

# Check status
```bash
$ virsh domstate suricata
running

$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.50 "hostname -f"
suricata.ot.local

$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.50 "ip -br a"
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             192.168.30.50/24 fe80::72d1:8405:ea3f:c2ed/64 
eth1             UP             
```

# Ansible structure

├── inventory.ini
├── suricata_configure_wazuh_alerts.yml
├── suricata_deploy_emerging_threats_open_rules.yml
├── suricata_deploy_specific_rules.yml
├── suricata_deploy.yml
├── templates
│   ├── purdue_ot.rules.j2
│   ├── tapif-promisc.service.j2
│   └── wazuh_purdue_rules.xml

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