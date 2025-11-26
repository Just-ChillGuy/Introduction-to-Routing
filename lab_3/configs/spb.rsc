/interface bridge
add name=loopback
add name=vpn
/interface vpls
add disabled=no l2mtu=1500 mac-address=02:D5:99:AF:81:85 name=eovpls remote-peer=172.16.6.2 vpls-id=65500:666
/ip pool
add name=dhcp_pool_vpn ranges=10.10.10.3-10.10.10.254
/ip dhcp-server
add address-pool=dhcp_pool_vpn disabled=no interface=vpn name=dhcp_vpn
/routing ospf instance
set [ find default=yes ] router-id=172.16.1.2
/interface bridge port
add bridge=vpn interface=ether5
add bridge=vpn interface=eovpls
/ip address
add address=172.16.1.2/32 interface=loopback network=172.16.1.2
add address=172.16.1.101/30 interface=ether3 network=172.16.1.100
add address=172.16.2.101/30 interface=ether4 network=172.16.2.100
add address=192.168.1.2/24 interface=ether5 network=192.168.1.0
add address=10.10.10.2/24 interface=vpn network=10.10.10.0
/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
/mpls ldp
set enabled=yes lsr-id=172.16.1.2 transport-address=172.16.1.2
/mpls ldp interface
add interface=ether3
add interface=ether4
add interface=ether5
/routing ospf network
add area=backbone network=172.16.1.100/30
add area=backbone network=172.16.2.100/30
add area=backbone network=192.168.1.0/24
add area=backbone network=172.16.1.2/32
/system identity
set name=R01_SPB
