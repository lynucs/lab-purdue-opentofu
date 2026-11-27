# Access to the machine
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20


Wazuh access ??
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20 'for p in 1514 1515; do timeout 2 bash -c "</dev/tcp/192.168.30.100/$p" && echo "Port $p : OK" || echo "Port $p : BLOQUÉ"; done'
Port 1514 : OK
Port 1515 : OK

# Rebuild the machine from scratch
$ tofu destroy -target=libvirt_volume.vm_idmz_disk -target=libvirt_cloudinit_disk.vm_idmz_cloudinit -target=libvirt_domain.vm_idmz
$ tofu apply


# 
$ ansible-playbook -i inventory.ini squid_deploy_with_selfcert.yml (old)
$ ansible-playbook -i inventory.ini squid_deploy_selfsignedcert.yml



# Tester le proxy SSL-Bump depuis le réseau OT
## unauthorized
 ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100   "curl -k -x http://192.168.20.20:3128 -I https://www.cisco.com"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0  3059    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 Connection established

HTTP/1.1 403 Forbidden
Server: squid/5.5
Mime-Version: 1.0
Date: Fri, 27 Nov 2026 09:46:45 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 3059
X-Squid-Error: ERR_ACCESS_DENIED 0
Vary: Accept-Language
Content-Language: en
X-Cache: MISS from squid.idmz.local
X-Cache-Lookup: NONE from squid.idmz.local:3128
Via: 1.1 squid.idmz.local (squid/5.5)
Connection: close


$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20 "sudo tail -n 5 /var/log/squid/access.log"
1795771579.282      8 192.168.30.100 TCP_DENIED/200 0 CONNECT www.cisco.com:443 - HIER_NONE/- -
1795771599.942     11 192.168.30.100 TCP_DENIED/200 0 CONNECT examplde.com:443 - HIER_NONE/- -
1795771599.942      0 192.168.30.100 NONE_NONE/403 387 HEAD https://examplde.com/ - HIER_NONE/- text/html
1795772283.646      6 192.168.30.100 TCP_DENIED/200 0 CONNECT www.cisco.com:443 - HIER_NONE/- -
1795772493.050      9 192.168.30.100 TCP_DENIED/200 0 CONNECT www.cisco.com:443 - HIER_NONE/- -

## Authorized
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "curl -I -v -k -x http://192.168.20.20:3128 https://example.com 2>&1 | grep -E '(issuer:|HTTP/)'" ; ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20 "sudo tail -n 2 /var/log/squid/access.log"
> CONNECT example.com:443 HTTP/1.1
< HTTP/1.1 200 Connection established
*  issuer: C=FR; O=Lab; CN=Squid Root CA
> HEAD / HTTP/1.1
< HTTP/1.1 200 OK
HTTP/1.1 200 Connection established
HTTP/1.1 200 OK
1795772580.957     58 192.168.30.100 NONE_NONE/200 0 CONNECT example.com:443 - HIER_DIRECT/172.66.147.243 -
1795772580.957      0 192.168.30.100 TCP_HIT/200 443 HEAD https://example.com/ - HIER_NONE/- text/html


La réponse HTTP/1.1 200 Connection established suivie de HTTP/1.1 200 OK avec les en-têtes Via: 1.1 squid.idmz.local (squid/5.5) et X-Cache: MISS from squid.idmz.local confirme que le routage OT (192.168.30.100) vers iDMZ (192.168.20.20:3128) ainsi que le déchiffrement SSL-Bump de Squid fonctionnent.

# Vérifier la journalisation dans access.log et la lecture par Wazuh
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20 "sudo tail -n 3 /var/log/squid/access.log && sudo grep -i 'access.log' /var/ossec/logs/ossec.log"
1795623113.182     71 192.168.30.100 NONE_NONE/200 0 CONNECT example.com:443 - HIER_DIRECT/172.66.147.243 -
1795623113.242     59 192.168.30.100 TCP_MISS/200 441 HEAD https://example.com/ - HIER_DIRECT/172.66.147.243 text/html
2026/11/25 16:06:12 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.
2026/11/25 16:06:18 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.
2026/11/25 16:06:26 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.
2026/11/25 16:06:59 wazuh-logcollector: WARNING: (1958): Log file '/var/log/squid/access.log' is duplicated.
2026/11/25 16:06:59 wazuh-logcollector: INFO: (1950): Analyzing file: '/var/log/squid/access.log'.

# Interroger le journal des alertes (alerts.json) dans le conteneur Manager
ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "sudo docker exec single-node-wazuh.manager-1 grep -E '\"groups\":\[.*\"squid\"' /var/ossec/logs/alerts/alerts.json | tail -n 2 | jq ."

# 2. Contrôler la réception des événements Squid sur le Manager
Vérifiez que les requêtes HTTP/HTTPS relayées par Squid sont bien reçues par le Manager (note : par défaut, Wazuh déclenche une alerte de niveau >= 3 uniquement sur les codes erreur 4xx/5xx comme TCP_DENIED/403, tandis que les 200 OK sont enregistrés dans archives.json si l'archivage est actif) :
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
  "curl -k -x http://192.168.20.20:3128 -I https://site-non-autorise-test.invalid 2>/dev/null; sudo docker exec single-node-wazuh.manager-1 grep -i 'squid' /var/ossec/logs/alerts/alerts.log | tail -n 5"
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



