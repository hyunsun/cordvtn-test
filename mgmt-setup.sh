#!/bin/bash

# Management
sudo ovs-vsctl add-br br-mgmt
sudo ovs-vsctl add-br br-ex
sudo ovs-vsctl add-port br-ex vxlan-c1 -- set interface vxlan-c1 type=vxlan options:remote_ip=159.203.255.221 options:local_ip=45.55.25.244 options:key=100
sudo ip link set br-mgmt up
sudo ip addr add 10.10.10.21/24 dev br-mgmt
sudo ifconfig br-mgmt mtu 1400
sudo ip link add veth2 type veth peer name veth3
sudo ip link set veth2 up
sudo ip link set veth3 up
sudo ovs-vsctl add-port br-mgmt veth2
