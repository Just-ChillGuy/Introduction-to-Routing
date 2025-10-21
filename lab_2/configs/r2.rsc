/ip pool
add name=dhcp_pool_brl ranges=192.168.2.3-192.168.2.200
/ip dhcp-server
add address-pool=dhcp_pool_brl disabled=no interface=ether5 name=dhcp_brl
/ip address
add address=10.10.10.2/30 interface=ether3
add address=20.20.20.1/30 interface=ether4
add address=192.168.2.2/24 interface=ether5
/ip dhcp-server network
add address=192.168.2.0/24 gateway=192.168.2.2
/ip route
add distance=1 dst-address=192.168.1.0/24 gateway=10.10.10.1
add distance=1 dst-address=192.168.3.0/24 gateway=20.20.20.2
/system identity
set name=R02_brl
