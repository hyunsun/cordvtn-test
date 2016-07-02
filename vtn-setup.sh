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
sudo ip link set address 00:00:00:00:00:01 dev fabric
sudo ip link set address 00:00:00:00:00:01 dev eth1
sudo ip address add 20.0.0.1/24 dev fabric
sudo ip address add 10.168.0.1/24 dev fabric
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Management
#sudo ovs-vsctl add-br br-mgmt
#sudo ovs-vsctl add-port br-ex vxlan-c1 -- set interface vxlan-c1 type=vxlan options:remote_ip=159.203.255.221 options:local_ip=45.55.25.244 options:key=100
#sudo ip link set br-mgmt up
#sudo ip addr add 10.10.10.21/24 dev br-mgmt
#sudo ifconfig br-mgmt mtu 1400
#sudo ip link add veth2 type veth peer name veth3
#sudo ip link set veth2 up
#sudo ip link set veth3 up
#sudo ovs-vsctl add-port br-mgmt veth2
