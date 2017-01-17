#!/bin/bash

sudo docker run --privileged --cap-add=ALL -d -v /dev:/dev -v /lib/modules:/lib/modules --name olt -t vlan /bin/bash
sudo ./pipework fabric -i eth1 olt 10.6.1.254/24
sudo docker exec -d olt modprobe 8021q
sudo docker exec -d olt vconfig add eth1 222
sudo docker exec -d olt ip link set eth1.222 up
sudo docker exec -d olt ip addr add 10.168.0.254/24 dev eth1.222
