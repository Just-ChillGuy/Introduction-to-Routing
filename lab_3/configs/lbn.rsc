/interface bridge
add name=loopback
/routing ospf instance
set [ find default=yes ] router-id=172.16.5.2
/ip address
add address=172.16.5.2 interface=loopback network=172.16.5.2
add address=172.16.4.102/30 interface=ether3 network=172.16.4.100
add address=172.16.5.102/30 interface=ether4 network=172.16.5.100
add address=172.16.7.101/30 interface=ether5 network=172.16.7.100
/mpls ldp
set enabled=yes lsr-id=172.16.5.2 transport-address=172.16.5.2
/mpls ldp interface
add interface=ether3
add interface=ether4
add interface=ether5
/routing ospf network
add area=backbone network=172.16.4.100/30
add area=backbone network=172.16.5.100/30
add area=backbone network=172.16.7.100/30
add area=backbone network=172.16.5.2/32
/system identity
set name=R01_LBN
