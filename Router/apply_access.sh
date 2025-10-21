#!/bin/bash

RULES_FILE="/etc/nftables.conf"
ACCESS_IP_FILE="/etc/router/access.ip"
ACCESS_MAC_FILE="/etc/router/access.mac"

echo "Leyendo IPs permitidas..."
ALLOWED_IPS=""
while IFS= read -r ip; do

    [[ -z "$ip" || "$ip" =~ ^# ]] && continue
    ALLOWED_IPS="$ALLOWED_IPS $ip,"
done < "$ACCESS_IP_FILE"
ALLOWED_IPS="${ALLOWED_IPS%,}"

echo "Leyendo MACs permitidas..."
ALLOWED_MACS=""
while IFS= read -r mac; do
    [[ -z "$mac" || "$mac" =~ ^# ]] && continue
    ALLOWED_MACS="$ALLOWED_MACS $mac,"
done < "$ACCESS_MAC_FILE"
ALLOWED_MACS="${ALLOWED_MACS%,}"

cat > "$RULES_FILE" << 'EOF'
#!/usr/sbin/nft -f
flush ruleset

define PROXY_IP = 10.10.4.1
define PROXY_HTTP_PORT = 3128
define PROXY_HTTPS_PORT = 3129
define INTERFACE_TO_PROXY = enx7cc2c646bf94


define ALLOWED_IPS = {EOF
echo "$ALLOWED_IPS }" >> "$RULES_FILE"

cat >> "$RULES_FILE" << 'EOF'

define ALLOWED_MACS = {EOF
echo "$ALLOWED_MACS }" >> "$RULES_FILE"

cat >> "$RULES_FILE" << 'EOF'

table inet nat {
        chain prerouting {
                type nat hook prerouting priority -100; policy accept;
                
                iifname "enp1s0.*" ip saddr $ALLOWED_IPS tcp dport 80 dnat ip to $PROXY_IP:$PROXY_HTTP_PORT
                iifname "enp1s0.*" ip saddr $ALLOWED_IPS tcp dport 443 dnat ip to $PROXY_IP:$PROXY_HTTPS_PORT
                
                iifname "enp1s0.*" ether saddr $ALLOWED_MACS tcp dport 80 dnat ip to $PROXY_IP:$PROXY_HTTP_PORT
                iifname "enp1s0.*" ether saddr $ALLOWED_MACS tcp dport 443 dnat ip to $PROXY_IP:$PROXY_HTTPS_PORT
        }
        
        chain postrouting {
                type nat hook postrouting priority 100; policy accept;
                oifname $INTERFACE_TO_PROXY ip saddr $ALLOWED_IPS counter masquerade
                oifname $INTERFACE_TO_PROXY ether saddr $ALLOWED_MACS counter masquerade
        }
}

table inet filter {
        chain input {
                type filter hook input priority 0; policy drop;
                
                iif lo accept
                ct state established,related accept
                

                iifname "enp1s0.*" ip saddr $ALLOWED_IPS udp dport 53 accept
                iifname "enp1s0.*" ip saddr $ALLOWED_IPS tcp dport 53 accept

                iifname "enp1s0.*" ether saddr $ALLOWED_MACS udp dport 53 accept
                iifname "enp1s0.*" ether saddr $ALLOWED_MACS tcp dport 53 accept
                

                iifname "enp1s0.*" ip saddr $ALLOWED_IPS ip protocol icmp accept

                iifname "enp1s0.*" ether saddr $ALLOWED_MACS ip protocol icmp accept
                

                iifname "enp1s0.*" ip saddr $ALLOWED_IPS tcp dport 22 accept
                iifname "enp1s0.*" ether saddr $ALLOWED_MACS tcp dport 22 accept
                
                iifname "enp1s0.*" ip saddr $ALLOWED_IPS accept

                iifname "enp1s0.*" ether saddr $ALLOWED_MACS accept
                
                iifname $INTERFACE_TO_PROXY ct state established,related accept
        }
        
        chain forward {
                type filter hook forward priority 0; policy drop;
                
                ct state established,related accept

                iifname "enp1s0.*" ip saddr $ALLOWED_IPS oifname $INTERFACE_TO_PROXY accept

                iifname "enp1s0.*" ether saddr $ALLOWED_MACS oifname $INTERFACE_TO_PROXY accept
                
                iifname $INTERFACE_TO_PROXY oifname "enp1s0.*" ip daddr $ALLOWED_IPS ct state established,related accept
                iifname $INTERFACE_TO_PROXY oifname "enp1s0.*" ct state established,related accept
                
                iifname "enp1s0.*" oifname "enp1s0.*" ip saddr $ALLOWED_IPS ip daddr $ALLOWED_IPS accept

                iifname "enp1s0.*" oifname "enp1s0.*" ether saddr $ALLOWED_MACS accept
        }
        
        chain output {
                type filter hook output priority 0; policy accept;
        }
}
EOF

echo "Aplicando reglas nftables"
nft -f "$RULES_FILE"

echo "IPs permitidas: $ALLOWED_IPS"
echo "MACs permitidas: $ALLOWED_MACS"

nft list ruleset

