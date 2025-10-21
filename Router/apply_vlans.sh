#!/bin/bash

VLAN_CONF="/etc/VLANs.conf"
ADMIN_VLAN="10"  #VLAN del admin
ADMIN_IFACE="enp1s0"  # Interfaz VLAN del admin

echo "=== Aplicando configuración de VLANs ==="

# Verifica que existe el archivo
if [ ! -f "$VLAN_CONF" ]; then
    echo "Error: No se encuentra $VLAN_CONF"
    exit 1
fi

declare -a VLANS_CONFIG=()

while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    VLAN_ID=$(echo "$line" | awk '{print $1}' | tr -d ' ')
    
    if [ -n "$VLAN_ID" ]; then
        VLANS_CONFIG+=("$VLAN_ID")
    fi
done < "$VLAN_CONF"

for vlan in $(ip -br link show | grep -E '\.[0-9]+' | awk '{print $1}'); do

    VLAN_NUM=$(echo "$vlan" | awk -F. '{print $NF}' | cut -d'@' -f1)
    IFACE_NAME=$(echo "$vlan" | awk -F. '{print $1}')
    VLAN_S=${vlan%@*}

    if [ "$VLAN_NUM" == "$ADMIN_VLAN" ] && [ "$IFACE_NAME" == "$ADMIN_IFACE" ]; then
        echo "[[Protegiendo VLAN admin: $VLAN_S]]"
        continue
    fi
    

    VLAN_S=${vlan%@*}
    if [[ ! " ${VLANS_CONFIG[@]} " =~ " ${VLAN_NUM} " ]]; then
        echo "Eliminando VLAN obsoleta: $VLAN_S"
        ip link set "$VLAN_S" down 2>/dev/null
        ip link delete "$VLAN_S" 2>/dev/null
    else
        echo "Manteniendo VLAN: $VLAN_S en configuración"
    fi
done

echo ""
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    VLAN_ID=$(echo "$line" | awk '{print $1}')
    INTERFACES=$(echo "$line" | awk '{for(i=2;i<=NF;i++) print $i}')
    
    
    for iface in $INTERFACES; do
        VLAN_NAME="${iface}.${VLAN_ID}"
        
        if ip link show "$VLAN_NAME" &> /dev/null; then
            ip link set "$VLAN_NAME" up 2>/dev/null
        else
            ip link add link "$iface" name "$VLAN_NAME" type vlan id "$VLAN_ID"
            ip link set "$VLAN_NAME" up
            echo "  - $VLAN_NAME creada y activada"
        fi
    done
    
done < "$VLAN_CONF"
