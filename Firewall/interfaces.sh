# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

#Conexion por wifi
# The primary network interface
#allow-hotplug wlan0
#iface wlan0 inet dhcp
#	wpa-ssid FamiliaPuSam
#	wpa-psk 12345678

#Conexion fisica por cable 
auto enp2s0
iface enp2s0 inet dhcp

#Conexion por cable USB
#auto usb0
allow-hotplug usb0
iface usb0 inet dhcp

#Conexion fisica Lan 1
#auto eth0
allow-hotplug eth0
iface eth0 inet static
	address 10.10.1.1
	netmask 255.255.255.252
	up ip route add 10.10.4.0/30 via 10.10.1.2 dev eth0 metric 100
	up ip route add 10.10.3.0/30 via 10.10.1.2 dev eth0 metric 100
	down ip route del 10.10.3.0/30 via 10.10.1.2 dev eth0 metric 100
	down ip route del 10.10.4.0/30 via 10.10.1.2 dev eth0 metric 100
#Conexion fisica Lan 2
#auto eth1
allow-hotplug eth1
iface eth1 inet static
	address 10.10.2.1
	netmask 255.255.255.252
	up ip route add 10.10.3.0/30 via 10.10.2.2 dev eth1 metric 200
	up ip route add 10.10.4.0/30 via 10.10.2.2 dev eth1 metric 200
	down ip route del 10.10.3.0/30 via 10.10.2.2 dev eth1 metric 200
	down ip route del 10.10.4.0/30 via 10.10.2.2 dev eth1 metric 200
