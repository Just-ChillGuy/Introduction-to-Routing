# Топология

Топология описывает виртуальную сеть, где несколько городов связаны между собой маршрутизаторами Mikrotik, а в Санкт-Петербурге и Нью-Йорке к этим маршрутизаторам подключены два обычных Linux-хоста — рабочий компьютер инженеров (PC1) и сервер SGI_PRISM. Все устройства имеют управляемые IP-адреса в одной подсети 192.168.10.0/24.

Маршрутизаторы образуют единое MPLS-ядро: Санкт-Петербург соединён с Хельсинки и Москвой, Хельсинки — с Лондоном и Ливаном, Ливан связан с Москвой и Нью-Йорком, а Нью-Йорк, в свою очередь, тоже имеет связь с Лондоном. PC1 подключён к роутеру в СПб, а SGI_PRISM — к роутеру в Нью-Йорке.

```
name: lab_3

mgmt: 
  network: static
  ipv4-subnet: 192.168.10.0/24

topology:
  kinds: 
    vr-mikrotik_ros: 
      image: vrnetlab/mikrotik_routeros:6.47.9
    linux: 
      image: alpine:latest
  nodes:
    R01.SPb:
      kind: vr-mikrotik_ros
      mgmt-ipv4: 192.168.10.11
      startup-config: configs/spb.rsc
    R01_HKI:
      kind: vr-mikrotik_ros
      mgmt-ipv4: 192.168.10.12
      startup-config: configs/hki.rsc
    R01_MSK:
      kind: vr-mikrotik_ros
      mgmt-ipv4: 192.168.10.13
      startup-config: configs/msk.rsc
    R01_LND:
      kind: vr-mikrotik_ros
      mgmt-ipv4: 192.168.10.14
      startup-config: configs/lnd.rsc
    R01_LBN:
      kind: vr-mikrotik_ros
      mgmt-ipv4: 192.168.10.15
      startup-config: configs/lbn.rsc
    R01_NY:
      kind: vr-mikrotik_ros
      mgmt-ipv4: 192.168.10.16
      startup-config: configs/ny.rsc
    PC1: 
      kind: linux
      binds: 
        - ./configs:/configs/
    SGI_PRISM:
      kind: linux
      binds: 
        - ./configs:/configs/    
  links: 
    - endpoints: ["R01.SPb:eth2", "R01_HKI:eth2"]
    - endpoints: ["R01.SPb:eth3", "R01_MSK:eth2"]
    - endpoints: ["R01.SPb:eth4", "PC1:eth2"] 
    - endpoints: ["R01_HKI:eth3", "R01_LND:eth2"]
    - endpoints: ["R01_HKI:eth4", "R01_LBN:eth2"]
    - endpoints: ["R01_LBN:eth3", "R01_MSK:eth3"]
    - endpoints: ["R01_LBN:eth4", "R01_NY:eth3"]
    - endpoints: ["R01_NY:eth2", "R01_LND:eth3"]
    - endpoints: ["R01_NY:eth4", "SGI_PRISM:eth2"]
```

<img width="1252" height="427" alt="image" src="https://github.com/user-attachments/assets/960a38e2-3099-4213-9537-e45ff198d692" />


# Настройка маршрутизаторов

На маршрутизаторе создаётся два мостовых интерфейса: один используется как loopback для служебных адресов, второй — как мост для VPN-сегмента. Затем поднимается VPLS-интерфейс с именем eovpls, который связывается с удалённым маршрутизатором по адресу 172.16.6.2 и работает под идентификатором 65500:666, формируя Ethernet-туннель через MPLS. Для локальной VPN-сети создаётся пул адресов 10.10.10.3–10.10.10.254, а на мосту vpn запускается DHCP-сервер, который раздаёт адреса клиентам.

Маршрутизатор получает собственный router-id 172.16.1.2, который назначается ему через loopback. На физических интерфейсах ether3, ether4 и ether5 задаются IP-адреса для линков, а также добавляется адрес для интерфейса vpn. В DHCP-профиле для сети 10.10.10.0/24 задаётся шлюз 10.10.10.1.

Далее включается MPLS-LDP: маршрутизатор объявляет свой LSR-ID 172.16.1.2 и использует тот же адрес как transport-address. В LDP добавляются интерфейсы ether3, ether4 и ether5, чтобы по ним выполнялся обмен метками. OSPF работает в backbone-зоне: туда включены все линковые сети, сеть за ether5, а также loopback-адрес как /32 для корректной маршрутизации MPLS. В конце маршрутизатор получает имя R01_SPB.

```
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
```

На этом маршрутизаторе также создаются два моста: loopback для служебного /32-адреса и vpn для локального VPN-сегмента. Затем поднимается VPLS-интерфейс eovpls, который организует Ethernet-туннель к удалённому маршрутизатору по адресу 172.16.1.2, используя тот же VPLS-ID 65500:666 — это вторая сторона того же EoMPLS-псевдопровода.

В OSPF маршрутизатор получает router-id 172.16.6.2. На интерфейс loopback назначается адрес 172.16.6.2/32. Сетевые интерфейсы ether3 и ether4 получают линковые /30-адреса для взаимодействия с соседями в MPLS-облаке, а через ether5 поднимается локальная сеть 192.168.2.0/30, которая затем включается в мост vpn. Сегмент vpn также получает адрес 10.10.10.1/24 — это шлюз для той же VPN-сети, к которой на другой стороне подключается eovpls.

После этого включается MPLS-LDP с использованием loopback-адреса как идентификатора и transport-address. Интерфейсы ether3, ether4 и ether5 добавляются как LDP-носители, чтобы по ним происходил обмен метками. В OSPF в область backbone включаются обе линковые сети, а также loopback-адрес /32, чтобы обеспечить построение корректных MPLS-путей.

```
/interface bridge
add name=loopback
add name=vpn
/interface vpls
add disabled=no l2mtu=1500 mac-address=02:5C:67:11:1C:D6 name=eovpls remote-peer=172.16.1.2 vpls-id=65500:666
/routing ospf instance
set [ find default=yes ] router-id=172.16.6.2
/interface bridge port
add bridge=vpn interface=ether5
add bridge=vpn interface=eovpls
/ip address
add address=172.16.6.2/32 interface=loopback network=172.16.6.2
add address=172.16.6.102/30 interface=ether3 network=172.16.6.100
add address=172.16.7.102/30 interface=ether4 network=172.16.7.100
add address=192.168.2.1/30 interface=ether5 network=192.168.2.0
add address=10.10.10.1/24 interface=vpn network=10.10.10.0
/mpls ldp
set enabled=yes lsr-id=172.16.6.2 transport-address=172.16.6.2
/mpls ldp interface
add interface=ether3
add interface=ether4
add interface=ether5
/routing ospf network
add area=backbone network=172.16.6.100/30
add area=backbone network=172.16.7.100/30
add area=backbone network=172.16.6.2/32
/system identity
set name=R01_NY
/user set admin password=192856
```

Маршрутизаторы R01_HKI, R01_MSK, R01_LND, и R01_LBN настроены как промежуточные устройства. Например, R01_MSK:

```
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
/user set admin password=192856
```

