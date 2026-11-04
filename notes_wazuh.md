To retrieve the password:grep -n -E "INDEXER_PASSWORD|DASHBOARD_PASSWORD|ADMIN_PASSWORD|password" docker-compose.yml




L'agent en version **v4.9.0** démarre désormais sans aucune erreur de syntaxe XML, et la communication sur les ports `1514` et `1515` vers le Manager (`192.168.30.100`) fonctionne.

Le blocage actuel est explicité par le message du Manager :

```text
ERROR: Invalid group: ot-network (from manager)
ERROR: Unable to add agent (from manager)

```

Wazuh refuse d'enrôler un agent dans un groupe tant que celui-ci n'a pas été explicitement déclaré au préalable sur le Manager (seul le groupe `default` existe nativement).

---

### Solution 1 : Créer le groupe `ot-network` sur le Manager (Recommandé)

Cette méthode permet de conserver votre organisation par zones Purdue et groupes d'agents.

1. **Créer le groupe dans le conteneur du Manager :**
Sur votre machine `wazuh-manager` (`192.168.30.100`) :


```bash
sudo docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -a -g ot-network

```


*Vérification :* La commande doit afficher `Group 'ot-network' created.`
2. **Vérifier les groupes disponibles :**
```bash
sudo docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -l

```


*Vérification :* Vous devez voir `default` et `ot-network`.
3. **Relancer l'agent sur la sonde Suricata :**
Sur la machine `suricata` (`192.168.30.50`) :
```bash
sudo systemctl restart wazuh-agent

```


4. **Confirmer la validation de la clé :**
```bash
sudo grep -iE "valid key received|connected to the server" /var/ossec/logs/ossec.log | tail -n 5

```


*Vérification :* La sortie doit afficher :
```text
wazuh-agentd: INFO: Valid key received
wazuh-agentd: INFO: Connected to the server 192.168.30.100:1514

```



---

### Solution 2 : Enrôler temporairement dans le groupe `default` seul

Si vous préférez assigner le groupe plus tard :

1. Éditez la section `<enrollment>` ou retirez la balise `<groups>` dans `/var/ossec/etc/ossec.conf` sur la sonde Suricata :
```bash
sudo sed -i 's/<groups>.*<\/groups>/<groups>default<\/groups>/g' /var/ossec/etc/ossec.conf

```


2. Redémarrez l'agent :
```bash
sudo systemctl restart wazuh-agent

```



---

### Contrôle final sur le Manager

Une fois l'enregistrement validé, vérifiez la présence de l'agent sur `wazuh-manager` :

```bash
sudo docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/manage_agents -l

```

*Résultat attendu :*

```text
Available agents: 
   ID: 001, Name: suricata-ids-ot, IP: any (ou 192.168.30.50)

```