#!/bin/bash
modprobe 8021q

ip link add link enp12s0 name enp12s0.40 type vlan id 40

ip link add name br40 type bridge

ip link set dev enp12s0.40 master br40

ip link set dev enp12s0.40 up

ip link set dev br40 up
