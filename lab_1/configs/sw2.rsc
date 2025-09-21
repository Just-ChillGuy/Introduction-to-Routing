/interface vlan
add name=vlan10_e3 vlan-id=10 interface=ether3
add name=vlan10_e4 vlan-id=10 interface=ether4
/interface bridge
add name=br_v10
/interface bridge port
add interface=vlan10_e3 bridge=br_v10
add interface=vlan10_e4 bridge=br_v10
/ip dhcp-client
add disabled=no interface=br_v10
/user add name=newadmin password=newadmin group=full
/system identity set name=SW2-Switch
