/interface bridge
add name=loopback
/routing ospf instance
set [ find default=yes ] router-id=172.16.3.2
/ip address
add address=172.16.3.2/32 interface=loopback network=172.16.3.2
add address=172.16.2.102/30 interface=ether3 network=172.16.1.100
add address=172.16.5.101/30 interface=ether4 network=172.16.5.100
/mpls ldp
set enabled=yes lsr-id=172.16.3.2 transport-address=172.16.3.2
/mpls ldp interface
add interface=ether3
add interface=ether4
/routing ospf network
add area=backbone network=172.16.2.100/30
add area=backbone network=172.16.5.100/30
add area=backbone network=172.16.3.2/32
/system identity
set name=R01_MSK
