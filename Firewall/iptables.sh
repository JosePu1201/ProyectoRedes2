#iptables para el firware 


sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X

sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT


# NAT para ambas salidas (WAN)
sudo iptables -t nat -A POSTROUTING -o enp2s0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o usb0 -j MASQUERADE

sudo iptables -A FORWARD -i eth0 -o enp2s0 -j ACCEPT
sudo iptables -A FORWARD -i eth1 -o enp2s0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o usb0 -j ACCEPT
sudo iptables -A FORWARD -i eth1 -o usb0 -j ACCEPT
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A FORWARD -p icmp -j ACCEPT

sudo sysctl -w net.ipv4.ip_forward=1

