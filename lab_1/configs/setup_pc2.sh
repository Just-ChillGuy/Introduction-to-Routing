#!/bin/sh
ip link add link eth2 name vlan20 type vlan id 20
ip addr add 10.10.20.10/24 dev vlan20
ip link set vlan20 up
udhcpc -i vlan20
