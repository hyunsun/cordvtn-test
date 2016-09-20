#!/bin/bash

# Management
sudo ovs-vsctl add-br br-mgmt
sudo ovs-vsctl add-port br-mgmt vxlan-c1 -- set interface vxlan-c1 type=vxlan options:remote_ip=107.170.228.96 options:local_ip=45.55.25.244 options:key=100
sudo ovs-vsctl add-port br-mgmt vxlan-c2 -- set interface vxlan-c2 type=vxlan options:remote_ip=198.199.96.13 options:local_ip=45.55.25.244 options:key=100
sudo ovs-vsctl add-port br-mgmt vxlan-c3 -- set interface vxlan-c3 type=vxlan options:remote_ip=162.243.151.127 options:local_ip=45.55.25.244 options:key=100
sudo ip link set br-mgmt up
sudo ip addr add 10.10.10.21/24 dev br-mgmt
sudo ifconfig br-mgmt mtu 1400
sudo ip link add veth2 type veth peer name veth3
sudo ip link set veth2 up
sudo ip link set veth3 up
sudo ovs-vsctl add-port br-mgmt veth2
