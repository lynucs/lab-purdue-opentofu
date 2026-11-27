# Access to the machine
ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20
ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20 "cat /etc/nginx/modsec/modsecurity.conf"

# preparation
mkdir -p ~/LAB/opentofu/ot/ansible/repositories
curl -L -o ~/LAB/opentofu/ot/ansible/repositories/coreruleset-4.14.0.tar.gz \
  https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.14.0.tar.gz


# launch the playbook
ansible-playbook -i inventory.ini --syntax-check nginx-rp_deploy.yml && ansible-playbook -i inventory.ini nginx-rp_deploy.yml

# test
$ curl http://192.168.30.10
hello world

$ wget --no-check-certificate -qO- https://192.168.20.20:8443/vm-ot/
hello world

# test issue - Request from an unauthorized network
``` bash
$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "curl -k -I -s https://192.168.20.20:8443/vm-ot/"
HTTP/1.1 403 Forbidden
Server: nginx/1.20.1
Date: Fri, 27 Nov 2026 10:14:56 GMT
Content-Type: text/html
Content-Length: 153
Connection: keep-alive
```

# test issue - Reach wrong page
``` bash
$ wget --no-check-certificate -S -O /dev/null "https://192.168.20.20:8443/vm-ot/?file=../../etc/passwd" ; sleep 3 ; ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "sudo docker exec single-node-wazuh.manager-1 grep '\"id\":\"100501\"' /var/ossec/logs/alerts/alerts.json | tail -n 1 | jq '{timestamp, rule: .rule.id, level: .rule.level, description: .rule.description}'"
--2026-11-27 11:02:20--  https://192.168.20.20:8443/vm-ot/?file=../../etc/passwd
Connecting to 192.168.20.20:8443... connected.
WARNING: The certificate of ‘192.168.20.20’ is not trusted.
WARNING: The certificate of ‘192.168.20.20’ doesn't have a known issuer.
The certificate's owner does not match hostname ‘192.168.20.20’
HTTP request sent, awaiting response... 
  HTTP/1.1 403 Forbidden
  Server: nginx/1.20.1
  Date: Fri, 27 Nov 2026 10:02:20 GMT
  Content-Type: text/html
  Content-Length: 153
  Connection: keep-alive
2026-11-27 11:02:20 ERROR 403: Forbidden.

{
  "timestamp": "2026-11-27T10:02:22.233+0000",
  "rule": "100501",
  "level": 10,
  "description": "ModSecurity WAF: requête bloquée (403) depuis 192.168.10.1 vers /vm-ot/?file=../../etc/passwd"
}
laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ 
```


# reste
Deux améliorations mineures optionnelles (durcissement)Restreindre le vhost Nginx au seul réseau IT dans reverse_proxy.conf.j2 :
Ajouter allow 192.168.10.0/24; deny all; dans le bloc server garantit que seules les machines du réseau IT peuvent solliciter le reverse proxy WAF, même si un autre sous-réseau route vers 192.168.20.20.   Isoler les répertoires temporaires ModSecurity (SecTmpDir / SecDataDir) :
Dans modsecurity_2.conf, SecTmpDir /tmp/ et SecDataDir /tmp/ fonctionnent, mais dédier /var/cache/modsecurity appartenant à nginx:nginx (0750) évite de partager /tmp avec d'autres processus.   
