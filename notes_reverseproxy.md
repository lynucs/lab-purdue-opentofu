# Access to the machine


# launch the playbook
ansible-playbook -i inventory.ini --syntax-check nginx-rp_deploy.yml && ansible-playbook -i inventory.ini nginx-rp_deploy.yml

# test
$ curl http://192.168.30.10
hello world

$ wget --no-check-certificate -qO- https://192.168.20.20:8443/vm-ot/
hello world


wget --no-check-certificate -S -O /dev/null https://192.168.20.20:8443/vm-ot/?file=../../etc/passwd
--2026-11-25 22:58:29--  https://192.168.20.20:8443/vm-ot/?file=../../etc/passwd
Connecting to 192.168.20.20:8443... connected.
WARNING: The certificate of ‘192.168.20.20’ is not trusted.
WARNING: The certificate of ‘192.168.20.20’ doesn't have a known issuer.
The certificate's owner does not match hostname ‘192.168.20.20’
HTTP request sent, awaiting response... 
  HTTP/1.1 403 Forbidden
  Server: nginx/1.20.1
  Date: Wed, 25 Nov 2026 21:58:29 GMT
  Content-Type: text/html
  Content-Length: 153
  Connection: keep-alive
2026-11-25 22:58:29 ERROR 403: Forbidden.






- name: Options ModSecurity
      ansible.builtin.lineinfile:
        path: /etc/nginx/modsec/modsecurity.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^#?SecRuleEngine', line: 'SecRuleEngine On' }
        - { regexp: '^#?SecAuditEngine', line: 'SecAuditEngine RelevantOnly' }
        - { regexp: '^#?SecAuditLogRelevantStatus', line: 'SecAuditLogRelevantStatus "^(?:5|4(?!04))"' }
        - { regexp: '^#?SecAuditLogFormat', line: 'SecAuditLogFormat JSON' }
        - { regexp: '^#?SecAuditLogType', line: 'SecAuditLogType Serial' }
        - { regexp: '^#?SecAuditLog\s+', line: 'SecAuditLog {{ modsec_audit_log }}' }
      notify: Reload nginx