/interface vlan
add name=vlan10 vlan-id=10 interface=ether3
add name=vlan20 vlan-id=20 interface=ether3
/ip address
add address=10.10.10.1/24 interface=vlan10
add address=10.10.20.1/24 interface=vlan20
/ip pool
add name=dhcp_pool_vlan10 ranges=10.10.10.100-10.10.10.200
add name=dhcp_pool_vlan20 ranges=10.10.20.100-10.10.20.200
/ip dhcp-server
add name=dhcp_vlan10 interface=vlan10 address-pool=dhcp_pool_vlan10 disabled=no
add name=dhcp_vlan20 interface=vlan20 address-pool=dhcp_pool_vlan20 disabled=no
/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
add address=10.10.20.0/24 gateway=10.10.20.1
/user add name=newadmin password=newadmin group=full
/system identity set name=R1-Router
