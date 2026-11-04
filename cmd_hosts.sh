ip route add 192.168.20.0/24 via 192.168.10.254
ip route add 192.168.30.0/24 via 192.168.10.254
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o enp3s0 -j MASQUERADE
