#!/bin/bash
modprobe 8021q

ip link set dev br30 up

ip link add link enp12s0 name enp12s0.30 type vlan id 30

ip link add name br30 type bridge

ip link set dev enp12s0.30 master br30

ip link set dev enp12s0.30 up

ip link set dev br30 up
