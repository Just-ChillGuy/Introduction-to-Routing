/ip pool
add name=dhcp_pool_msk ranges=192.168.1.3-192.168.1.200
/ip dhcp-server
add address-pool=dhcp_pool_msk disabled=no interface=ether5 name=dhcp_msk
/ip address
add address=10.10.10.1/30 interface=ether3
add address=30.30.30.2/30 interface=ether4
add address=192.168.1.2/24 interface=ether5
/ip dhcp-server network
add address=192.168.1.0/24 gateway=192.168.1.2
/ip route
add distance=1 dst-address=192.168.2.0/24 gateway=10.10.10.2
add distance=1 dst-address=192.168.3.0/24 gateway=30.30.30.1
/system identity
set name=R01_msk
