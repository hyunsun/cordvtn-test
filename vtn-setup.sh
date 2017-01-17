#!/bin/bash

# Data
sudo brctl addbr fabric
sudo ip link set fabric up
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 up
sudo brctl addif fabric veth0
sudo brctl addif fabric eth1
sudo ip addr flush eth1
sudo ip link set address 02:42:0a:06:01:01 dev fabric
sudo ip link set address 02:42:0a:06:01:01 dev eth1
sudo ip address add 10.6.1.193/26 dev fabric
sudo ip address add 10.6.1.129/26 dev fabric
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -I FORWARD 1 -s 10.6.1.193 -m mac --mac-source 02:42:0a:06:01:01 -m physdev --physdev-out eth1 -j DROP
