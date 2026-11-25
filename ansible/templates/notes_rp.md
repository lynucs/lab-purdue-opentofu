laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ ssh -i ~/.ssh/id_ed25519 rocky@192.168.20.20 \
  "sudo sed -i 's|proxy_pass http://192.168.30.10;|proxy_pass http://192.168.30.10/;|' /etc/nginx/conf.d/protected_reverse_proxy.conf && sudo nginx -t && sudo systemctl reload nginx"
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
laurent@laurent-MS-A2:~/LAB/opentofu/ot/ansible$ wget --no-check-certificate -qO- https://192.168.20.20:8443/vm-ot/