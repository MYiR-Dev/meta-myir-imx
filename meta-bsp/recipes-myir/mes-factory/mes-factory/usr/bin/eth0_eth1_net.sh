#!/bin/sh


ifconfig eth0 down
ifconfig eth1 down
##
ETH0_MAC=80:31:DC:FF:81:30
ETH1_MAC=80:31:DC:FF:81:31

ifconfig eth0 hw ether $ETH0_MAC
ifconfig eth1 hw ether $ETH1_MAC
sleep 2
ifconfig eth0 192.168.1.1 netmask 255.255.255.0
ifconfig eth1 192.168.1.2 netmask 255.255.255.0


#ip route flush table all
route add 192.168.1.11 dev eth0
route add 192.168.1.22 dev eth1


arp -i eth0 -s 192.168.1.11 $ETH1_MAC
arp -i eth1 -s 192.168.1.22 $ETH0_MAC


iptables -t nat -F

iptables -t nat -A POSTROUTING  -s 192.168.1.1  -d 192.168.1.11 -j SNAT --to-source             192.168.1.22
iptables -t nat -A PREROUTING   -s 192.168.1.22 -d 192.168.1.11 -j DNAT --to-destination        192.168.1.2

iptables -t nat -A POSTROUTING  -s 192.168.1.2  -d 192.168.1.22 -j SNAT --to-source             192.168.1.11
iptables -t nat -A PREROUTING   -s 192.168.1.11 -d 192.168.1.22 -j DNAT --to-destination        192.168.1.1
