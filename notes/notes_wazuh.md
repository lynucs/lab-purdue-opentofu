# Access to the machine
ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100

# Add an agent
ansible-playbook -i inventory.ini wazuh_deploy_agent.yml -e "target_hosts=squid wazuh_agent_group=ot-network"

# Install wazuh-manager
$ ansible-playbook -i inventory.ini wazuh_deploy_agent.yml -e "target_hosts=squid wazuh_agent_group=default"

$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 \
  "sudo docker exec -i single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -a -g ot-network -q"
Group 'ot-network' created.


# get the password
[rocky@wazuh-manager ~]$ grep -n -E "INDEXER_PASSWORD|DASHBOARD_PASSWORD|ADMIN_PASSWORD|password" /opt/wazuh-docker/single-node/docker-compose.yml 
24:      - INDEXER_PASSWORD=SecretPassword
81:      - INDEXER_PASSWORD=SecretPassword
84:      - DASHBOARD_PASSWORD=kibanaserver

admin/SecretPassword

# List groups on azuh-manager

$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_groups -l"

# List of available agents

$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_control -l"

Wazuh agent_control. List of available agents:
   ID: 000, Name: wazuh.manager (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: suricata-ids-ot, IP: any, Active
   ID: 003, Name: squid, IP: any, Disconnected
   ID: 004, Name: webrelay, IP: any, Active

List of agentless devices:

# Remove an agent
ssh -i ~/.ssh/id_ed25519 rocky@192.168.30.100 "sudo docker exec single-node-wazuh.manager-1 /var/ossec/bin/manage_agents -r 003"


