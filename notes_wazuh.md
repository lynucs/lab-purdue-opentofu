
ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100


ansible-playbook -i inventory.ini wazuh_deploy_agent.yaml -e "target_hosts=squid wazuh_agent_group=default"

[rocky@wazuh-manager ~]$ grep -n -E "INDEXER_PASSWORD|DASHBOARD_PASSWORD|ADMIN_PASSWORD|password" /opt/wazuh-docker/single-node/docker-compose.yml 
24:      - INDEXER_PASSWORD=SecretPassword
81:      - INDEXER_PASSWORD=SecretPassword
84:      - DASHBOARD_PASSWORD=kibanaserver

admin/SecretPassword

laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
  "sudo docker exec -i single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -a -g ot-network -q"
Group 'ot-network' created.

ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
"sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -l"

$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -l"
Groups (2):
  default (1)
  ot-network (1)
Unassigned agents: 0.


laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
  "sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_control -l"

Wazuh agent_control. List of available agents:
   ID: 000, Name: wazuh.manager (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: suricata-ids-ot, IP: any, Active
   ID: 002, Name: squid, IP: any, Active

List of agentless devices:



# Tester le proxy SSL-Bump depuis le réseau OT
$laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
  "curl -k -x http://192.168.20.10:3128 -I https://example.com"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0HTTP/1.1 200 Connection established

HTTP/1.1 200 OK
Date: Wed, 25 Nov 2026 16:11:53 GMT
Content-Type: text/html; charset=utf-8
Server: cloudflare
Last-Modified: Tue, 24 Nov 2026 17:35:01 GMT
Allow: GET, HEAD
Accept-Ranges: bytes
Age: 6
cf-cache-status: HIT
CF-RAY: a601ee89bac1890e-MRS
alt-svc: h3=":443"; ma=86400
X-Cache: MISS from squid.idmz.local
X-Cache-Lookup: MISS from squid.idmz.local:3128
Via: 1.1 squid.idmz.local (squid/5.5)
Connection: keep-alive

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ 

La réponse HTTP/1.1 200 Connection established suivie de HTTP/1.1 200 OK avec les en-têtes Via: 1.1 squid.idmz.local (squid/5.5) et X-Cache: MISS from squid.idmz.local confirme que le routage OT (192.168.30.100) vers iDMZ (192.168.20.10:3128) ainsi que le déchiffrement SSL-Bump de Squid fonctionnent.

# Vérifier la journalisation dans access.log et la lecture par Wazuh
laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.10 \
  "sudo tail -n 3 /var/log/squid/access.log && sudo grep -i 'access.log' /var/ossec/logs/ossec.log"
1795623113.182     71 192.168.30.100 NONE_NONE/200 0 CONNECT example.com:443 - HIER_DIRECT/172.66.147.243 -
1795623113.242     59 192.168.30.100 TCP_MISS/200 441 HEAD https://example.com/ - HIER_DIRECT/172.66.147.243 text/html
2026/11/25 16:06:12 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.
2026/11/25 16:06:18 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.
2026/11/25 16:06:26 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.
2026/11/25 16:06:59 wazuh-logcollector: WARNING: (1958): Log file '/var/log/squid/access.log' is duplicated.
2026/11/25 16:06:59 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.

# 2. Contrôler la réception des événements Squid sur le Manager
Vérifiez que les requêtes HTTP/HTTPS relayées par Squid sont bien reçues par le Manager (note : par défaut, Wazuh déclenche une alerte de niveau >= 3 uniquement sur les codes erreur 4xx/5xx comme TCP_DENIED/403, tandis que les 200 OK sont enregistrés dans archives.json si l'archivage est actif) :

laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
  "curl -k -x http://192.168.20.10:3128 -I https://site-non-autorise-test.invalid 2>/dev/null; sudo docker exec single-node-wazuh.manager-1 grep -i 'squid' /var/ossec/logs/alerts/alerts.log | tail -n 5"
HTTP/1.1 200 Connection established

HTTP/1.1 403 Forbidden
Server: squid/5.5
Mime-Version: 1.0
Date: Wed, 25 Nov 2026 16:15:24 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 3093
X-Squid-Error: ERR_ACCESS_DENIED 0
Vary: Accept-Language
Content-Language: en
X-Cache: MISS from squid.idmz.local
X-Cache-Lookup: NONE from squid.idmz.local:3128
Via: 1.1 squid.idmz.local (squid/5.5)
Connection: close

====



