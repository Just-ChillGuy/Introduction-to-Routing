#!/bin/sh
udhcpc -i eth2
ip route del default via 192.168.50.1 dev eth0
