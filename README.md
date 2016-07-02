### Setup environment
![](https://66.media.tumblr.com/13cb8292cbffe48e2a9cf7cd0585f8af/tumblr_o8ongaffaz1s0jpjfo2_r1_540.png)
```
$ vtn-setup.sh
```

### Create virtual network and VMs
```
neutron net-create net-A
neutron subnet-create net-A 192.168.0.0/24
neutron net-create net-B
neutron subnet-create net-B 192.168.1.0/24
neutron net-create net-public
neutron subnet-create net-public 20.0.0.0/24
neutron net-create net-management
neutron subnet-create net-management 172.27.0.0/24

nova boot --flavor 2 --image ubuntu-14.04-server-cloudimg-amd64 --user-data passwd.data --nic net-id=[net-A-UUID] net-A-01
nova boot --flavor 2 --image ubuntu-14.04-server-cloudimg-amd64 --user-data passwd.data --nic net-id=[net-A-UUID] net-A-02
nova boot --flavor 2 --image ubuntu-14.04-server-cloudimg-amd64 --user-data passwd.data --nic net-id=[net-B-UUID] net-B-01
nova boot --flavor 2 --image trusty-server-multi-nic --user-data passwd.data --nic net-id=[net-public-UUID] --nic net-id=[net-management-UUID] net-public-01
```
Flow counts
Created net-A-01: 19/22
Created net-A-02: 23/23
Created net-B-01: 26/29
Created net-public-01: 37/32

### 1 basic tenant network test
* Can ping between net-A-01 and net-A-02
* Can’t ping between net-A-01 and net-B-01

### 2 local management and public network test
* Can ping to management IP of net-public-01 from the host compute machine
* Can ping 8.8.8.8 from net-public-01

### 3 service dependency test
Create service dependency between net-A and net-B
```
curl -X POST -u onos:rocks http://$OC1:8181/onos/cordvtn/service-dependency/[net-B-UUID]/[net-A-UUID]/b
```
Flow counts: 40/36

* Can ping between net-A-01 and net-B-01
* `tcpdump -i eth0 icmp` on net-A-01 and net-A-02, ping 192.168.0.1 from net-B-01, one of net-A VMs gets icmp request

Remove service dependency
```
curl -X DELETE -u onos:rocks http://$OC1:8181/onos/cordvtn/service-dependency/[net-B-UUID]/[net-A-UUID]/b
```
Flow counts: 33/31

* Can’t ping between net-A-01 and net-B-01
* Ping 192.168.0.1 from net-B-01 and the remaining net-A VM can’t get the icmp request

### 4 flow rule removing test
* Remove all VMs
* Check the rule count on `br-int` is 16

### 5 vSG test
![](https://67.media.tumblr.com/26e09e11f90fc45d139c0561bc34ab15/tumblr_o8ongaffaz1s0jpjfo1_r1_540.png)
```
                "publicGateways" : [
                    {
                        "gatewayIp" : "20.0.0.1",
                        "gatewayMac" : "00:00:00:00:00:01"
                    },
                    {
                        "gatewayIp" : "10.168.0.1",
                        "gatewayMac" : "00:00:00:00:00:01"
                    }
                ],
```
Add a new public gateway in the network config like above for the vSG WAN.

Add a container(with `vlan` package installed) which roles as an OLT device in compute node.
```
$ cd docker-olt
docker-olt $ docker build . -t vlan
docker-olt $ ./run-olt.sh
```

Create a network with the name including `vsg` and a port with port name `stag-222` for the network, and then create a VM with the port and public network. Update port with vSG WAN IP.
```
neutron net-create net-vsg
neutron subnet-create net-vsg 10.0.0.0/24
neutron port-create [net-vsg-UUID] --name stag-222
nova boot --flavor 2 --image trusty-server-multi-nic --user-data passwd.data --nic net-id=[net-public-UUID] --nic port-id=[port-stag222-UUID] vsg-01
neutron port-update [port-UUID] --allowed-address-pairs type=dict list=true ip_address=10.168.0.3,mac_address=00:00:00:00:00:10
```

Login to the vSG VM and install `vlan` package, add VLAN interfaces, assign IPs to the interfaces, and change the default gateway to `10.168.0.1`.
```
sudo apt-get update
sudo apt-get install vlan
sudo modprobe 8021q
sudo vconfig add eth1 222
sudo vconfig add eth1 500
sudo ip link set eth1.222 up
sudo ip link set eth1.500 up
sudo ip addr add 10.169.0.3/24 dev eth1.222
sudo ip addr add 10.168.0.3/24 dev eth1.500
sudo route del default gw 20.0.0.1
sudo route add default gw 10.168.0.1
```
Flow count: 19/25
* Can ping to 8.8.8.8 from `vsg-01`
* Can ping to 10.169.0.254 from `vsg-01`

## 6 Access agent test
Use the OLT device container in the previous test. Create another container for access agent and add one interface to `br-mgmt` and the other to `br-int`.
```
sudo docker run --privileged --cap-add=ALL -d --name access-agent -t ubuntu:14.04 /bin/bash
sudo ./pipework br-mgmt -i eth1 access-agent 10.10.10.100/24
sudo ./pipework br-int -i eth2 access-agent 10.168.0.100/24 00:00:00:00:02:22
```

Push access agent config to ONOS.
```
{
        "devices": {
                "of:0000000000000001": {
                        "accessAgent": {
                                "olts": {
                                        "of:0000000000000011/1": "00:00:00:00:00:11",
                                        "of:0000000000000011/2": "00:00:00:00:00:12"
                                },
                                "mac": "00:00:00:00:01:11",
                                "vtn-location": "of:0000000000000001/4"
                        }
                },
                "of:0000000000000002": {
                        "accessAgent": {
                                "olts": {
                                        "of:0000000000000022/1": "00:00:00:00:00:11",
                                        "of:0000000000000022/2": "00:00:00:00:00:12"
                                },
                                "mac": "00:00:00:00:02:22",
                                "vtn-location": "of:0000000000000002/14"
                        }
                }
        }
}
```
* Can ping to ONOS instance with management IP address
* Can hping to OLT device container's eth1 MAC address

## 7 dynamic service VM add and remove (XOS required) test
Run `make vtn` and `make cord`, **flow counts: 25/16**
Login to the `xos_ui` container on the XOS machine and run the following command.
```
python /opt/xos/tosca/run.py padmin@vicci.org /opt/xos/tosca/samples/vtn-service-chain.yaml
```
Check test VMs are created.
```
# nova list --all-tenants
+--------------------------------------+--------------+--------+------------+-------------+---------------------------------------------------+
| ID                                   | Name         | Status | Task State | Power State | Networks                                          |
+--------------------------------------+--------------+--------+------------+-------------+---------------------------------------------------+
| 4f5e4e25-3d84-41a9-9a47-25d88b4de65f | mysite_one-2 | ACTIVE | -          | Running     | management=172.27.0.4; one_access=10.0.3.2        |
| b893273d-ff15-4467-87a3-1171e4a3969e | mysite_two-3 | ACTIVE | -          | Running     | management=172.27.0.3; two_access=10.0.4.2        |
| 46504f0a-61a6-4201-a5b9-19614499bba5 | mysite_vsg-1 | ACTIVE | -          | Running     | management=172.27.0.2; mysite_vsg-access=10.0.2.2 |
+--------------------------------------+--------------+--------+------------+-------------+---------------------------------------------------+
```
Flow count: 39/34

Add one more VM to `two_access` network manually.
```
nova boot --flavor 2 --image trusty-server-multi-nic --user-data passwd.data --nic net-id=[two_access-UUID] mysite_two-4
```
* `tcpdump -i eth0 icmp` on `mysite_two-3` and `mysite_two-4`, ping `10.0.4.1` from `mysite_one-2`, check one of the access one network VM gets the icmp request
* Remove the access one VM which gets the icmp request, and check the other access one VM gets the icmp request
