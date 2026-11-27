# Récupération du certificat d'administration (SuperAdmin)
EJBCA sécurise son interface d'administration Web par authentification mutuelle TLS (mTLS). Un certificat client administrateur superadmin.p12 est généré automatiquement au premier démarrage du conteneur.

Surveiller les logs jusqu'à la fin de l'initialisation :
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 "sudo docker logs -f ejbca"


2026-10-25 17:19:13,004+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) ********************************************************************************************
2026-10-25 17:19:13,006+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Keystore password found at /opt/keyfactor/secrets/persistent/tls/ejbca.it.local/server.storepasswd
2026-10-25 17:19:13,008+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) We recommend using 'APPSERVER_KEYSTORE_SECRET' env variable to set the TLS keystore password.
2026-10-25 17:19:13,009+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) ********************************************************************************************
2026-10-25 17:19:13,011+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) No key password file were detected at '/opt/keyfactor/secrets/persistent/tls/ejbca.it.local/server.keypasswd'. Keystore password will also be used to access private key.
2026-10-25 17:19:13,015+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Importing keystore /opt/keyfactor/secrets/persistent/tls/ejbca.it.local/server.p12 to /opt/keyfactor/tmp/tmp.T2lGJl5ckV/keystore.p12...
2026-10-25 17:19:13,015+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Entry for alias ejbca.it.local successfully imported.
2026-10-25 17:19:13,015+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Import command completed:  1 entries successfully imported, 0 entries failed or cancelled
2026-10-25 17:19:13,459+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Using a previously generated server side TLS keystore.
2026-10-25 17:19:17,132+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Adding initial application RoleMember (";PublicAccessAuthenticationToken:TRANSPORT_CONFIDENTIAL;").
2026-10-25 17:19:18,681+0000 INFO  [org.cesecore.audit.impl.log4j.Log4jDevice] (default task-3) 2026-10-25 17:19:18Z;ROLE_ACCESS_USER_ADDITION;SUCCESS;ROLES;CORE;ejbca;;;;msg=Added administrator aspect(s)  to role Super Administrator Role.;id=71319268;tokenType=PublicAccessAuthenticationToken;tokenIssuerId=0;tokenProviderId=0;tokenMatchKey=TRANSPORT_CONFIDENTIAL (2);tokenMatchOperator=TYPE_UNUSED (0);tokenMatchValue=;roleId=1;nameSpace=;roleName=Super Administrator Role;description=Initial RoleMember.
2026-10-25 17:19:18,686+0000 INFO  [org.ejbca.ui.cli.roles.AddRoleMemberCommand] (main) Role member was successfully added.
2026-10-25 17:19:19,007+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Setting up TLS truststore configuration.
2026-10-25 17:19:19,009+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) No truststore and/or password file were detected at '/opt/keyfactor/secrets/external/tls/ts/truststore.[p12|jks|storepasswd]'. Check mount points and file permissions if this is not what you expected.
2026-10-25 17:19:19,011+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Building truststore from available sources.
2026-10-25 17:19:19,013+0000 INFO  [/opt/keyfactor/bin/start.sh] (process:1) Adding application trust certificates from EJBCA.
2026-10-25 17:19:20,739+0000 INFO  [org.ejbca.ui.cli.ca.GetAdminTruststoreCommand] (main) /opt/keyfactor/tmp/tmp.T2lGJl5ckV/truststore.p12 created.

# Tester la réponse de santé depuis l'hôte

curl -k http://192.168.10.100/ejbca/publicweb/healthcheck/ejbcahealth

# Accès via : https://192.168.10.100/ejbca/adminweb/

Pas besoin de superadmin.p12. 'est tout à fait normal avec cette version de l'image Docker : la ligne des logs `Adding initial application RoleMember (";PublicAccessAuthenticationToken:TRANSPORT_CONFIDENTIAL;")` confirme qu'EJBCA s'est initialisé en autorisant un accès d'administration public temporaire via TLS (`TRANSPORT_CONFIDENTIAL`), sans exiger de certificat client mTLS préalable.

De plus, l'arborescence interne a changé sur les images récentes : les binaires et données sont désormais sous `/opt/keyfactor/` au lieu de l'ancien chemin historique `/opt/primekey/`.

---

### Configuration recommandée depuis l'interface Web

Puisque vous avez accès à la console d'administration (`/ejbca/adminweb/`) :

1. **Création d'une autorité de certification (CA) :**
* Rendez-vous dans **CA Functions** $\rightarrow$ **Certificate Authorities**.
* Créez une nouvelle autorité (ex: `LabRootCA` ou `OT_SubCA`) avec les algorithmes souhaités (RSA 4096 ou ECDSA P-256/P-384).


2. **Génération ultérieure du certificat SuperAdmin (optionnel) :**
Si vous souhaitez par la suite verrouiller l'accès Web et restreindre la console aux seuls détenteurs d'un certificat mTLS :
* Allez dans **Enrollment** $\rightarrow$ **Use Username/Passwords** ou créez une entité de fin (*End Entity*) nommée `superadmin`.
* Associez-la au profil administrateur, téléchargez le fichier `.p12` directement depuis le navigateur, puis retirez le jeton `PublicAccessAuthenticationToken` dans les rôles système (**Administrator Roles** $\rightarrow$ **Super Administrator Role**).


3. **Vérification de la persistance des données :**
Assurez-vous que le volume Docker conserve bien vos créations lors d'un éventuel redémarrage du conteneur en inspectant le point de montage :
```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 "sudo docker inspect ejbca --format '{{ json .Mounts }}'"

```


ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca init --help'

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca init \
  --caname "RootCA" \
  --dn "CN=Root CA,OU=IT,O=Lab,C=FR" \
  --tokenType soft \
  --tokenName "RootCA_Token" \
  --tokenPass null \
  --keyspec P-256 \
  -s SHA256WithECDSA \
  -v 5478 \
  --policy null'

List les CAs:
--------------
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca listcas'


ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca info "RootCA" | grep -E "(CA name:|CA ID:
)"'

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca init \
  --caname "subca01" \
  --dn "CN=subca01,OU=IT,O=Lab,C=FR" \
  --tokenType soft \
  --tokenName "subca01_Token" \
  --tokenPass null \
  --keyspec P-256 \
  -s SHA256WithECDSA \
  -v 3650 \
  --signedby 852328287 \
  -certprofile SUBCA \
  --policy null'



ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca init \
  --caname "subca02" \
  --dn "CN=subca02,OU=IT,O=Lab,C=FR" \
  --tokenType soft \
  --tokenName "subca02_Token" \
  --tokenPass null \
  --keyspec P-256 \
  -s SHA256WithECDSA \
  -v 3650 \
  --signedby 852328287 \
  -certprofile SUBCA \
  --policy null'

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca getcacert --caname "subca02" -f /tmp/subca02.pem'
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca cat /tmp/subca02.pem' | openssl x509 -text -noout
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca cat /tmp/subca02.pem' | openssl x509 -text -noout | grep -A 2 -i "Basic Constraints"
L'extension X.509 Basic Constraints y est configurée avec une contrainte de longueur de chemin (Path Length Constraint) fixée à 0 (PathLen=0), interdisant à cette autorité subordonnée d'émettre des certificats pour d'autres CA.



ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca init \
  --caname "SubCAChain" \
  --dn "CN=SubCAChain,OU=IT,O=Lab,C=FR" \
  --tokenType soft \
  --tokenName "subcachainToken" \
  --tokenPass null \
  --keyspec P-256 \
  -s SHA256WithECDSA \
  -v 3650 \
  --signedby 852328287 \
  -certprofile SUBCACHAIN \
  --policy null'

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca getcacert --caname "SubCAChain" -f /tmp/subcachain.pem'
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca cat /tmp/subcachain.pem' | openssl x509 -text -noout | grep -A 2 -i "Basic Constraints"

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca init \
  --caname "SubCAIds" \
  --dn "CN=SubCAIds,OU=IT,O=Lab,C=FR" \
  --tokenType soft \
  --tokenName "subcaidsnToken" \
  --tokenPass null \
  --keyspec P-256 \
  -s SHA256WithECDSA \
  -v 3650 \
  --signedby 1714082804 \
  -certprofile SUBCAIDS \
  --policy null'

ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca /opt/keyfactor/ejbca/bin/ejbca.sh ca getcacert --caname "SubCAIds" -f /tmp/subcaids.pem'
ssh -i ~/.ssh/id_ed25519 ubuntu@192.168.10.100 'sudo docker exec ejbca cat /tmp/subcaids.pem' | openssl x509 -text -noout | grep -A 2 -i "Basic Constraints"
