# Топология:

В лабораторной работе развернута сетевая инфраструктура для компании "RogaIKopita Games" на основе ContainerLab. Схема включает шесть маршрутизаторов Mikrotik RouterOS и три Linux-хоста, соединенных согласно техническому заданию. Все устройства объединены в единую управляющую сеть с выделением индивидуальных IP-адресов. Данная конфигурация служит платформой для поэтапного внедрения технологий: в первой части работы настраивается IP/MPLS с изолированными VRF, во второй — та же физическая топология перестраивается под сервис VPLS, что позволяет выполнить все поставленные учебные цели.

```
name: lab4-part1
mgmt:
  network: custom_mgmt
  ipv4-subnet: 172.16.16.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9

  nodes:
    R01.SPB:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.101
      startup-config: config/part1/r01-spb.rsc
    R01.HKI:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.102
      startup-config: config/part1/r01-hki.rsc
    R01.SVL:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.103
      startup-config: config/part1/r01-svl.rsc
    R01.LND:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.104
      startup-config: config/part1/r01-lnd.rsc
    R01.LBN:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.105
      startup-config: config/part1/r01-lbn.rsc
    R01.NY:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.106
      startup-config: config/part1/r01-ny.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.2
      binds:
        - ./config:/config
    PC2:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.3
      binds:
        - ./config:/config
    PC3:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.4
      binds:
        - ./config:/config


  links:
    - endpoints: ["R01.SPB:eth1","R01.HKI:eth1"]
    - endpoints: ["R01.NY:eth1","R01.LND:eth1"]
    - endpoints: ["R01.SVL:eth1","R01.LBN:eth1"]
    - endpoints: ["R01.HKI:eth2","R01.LND:eth3"]
    - endpoints: ["R01.HKI:eth3","R01.LBN:eth2"]
    - endpoints: ["R01.LND:eth2","R01.LBN:eth3"]
    - endpoints: ["R01.SPB:eth2","PC1:eth1"]
    - endpoints: ["R01.NY:eth2","PC2:eth1"]
    - endpoints: ["R01.SVL:eth2","PC3:eth1"]
    

```

<img width="1342" height="792" alt="image" src="https://github.com/user-attachments/assets/a37e65c6-9c8e-4328-aaf3-531be01eec9e" />

# Первая часть задания:

Пограничные маршрутизаторы, к которым подключены клиентские хосты, были подготовлены для работы в составе IP/MPLS-сети. На них подняты loopback-интерфейсы, настроены протоколы OSPF (в зоне 0) и BGP для обмена маршрутами, а также активирован DHCP для автоматической настройки клиентских устройств.
Для изоляции и передачи клиентского трафика была внедрена технология VRF. Для каждого VRF заданы параметры RD (Route Distinguisher) и RT (Route Target) для импорта и экспорта маршрутов, а клиентские интерфейсы закреплены за соответствующими VRF-инстансами. Для обеспечения туннелирования на интерфейсах ядра включен MPLS с протоколом LDP. Настройка пиринга между BGP-роутерами позволяет обмениваться не только обычными, но и VPNv4-префиксами. В итоге конфигурация позволяет этим роутерам полноценно функционировать в роли граничных узлов Provider Edge (PE), обеспечивая клиентам доступ к сервисам поверх единой транспортной сети.

R01_spb:

```
/system identity
set name=R01.SPB

/ip address
add address=10.20.1.1/30 interface=ether2
add address=192.168.10.1/24 interface=ether3

/ip pool
add name=dhcp-pool ranges=192.168.10.10-192.168.10.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether3 name=dhcp-server
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.1/32 interface=loopback network=10.255.255.1

/routing ospf instance
add name=inst router-id=10.255.255.1
/routing ospf area
add name=backbonev2 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev2 network=10.20.1.0/30
add area=backbonev2 network=192.168.10.0/24
add area=backbonev2 network=10.255.255.1/32

/mpls ldp
set lsr-id=10.255.255.1
set enabled=yes transport-address=10.255.255.1
/mpls ldp interface
add interface=ether2

/routing bgp instance
set default as=65000 router-id=10.255.255.1
/routing bgp peer
add name=peerHKI remote-address=10.255.255.2 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no 
/routing bgp network
add network=10.255.255.0/24

/interface bridge 
add name=br100
/ip address
add address=10.100.1.1/32 interface=br100
/ip route vrf
add export-route-targets=65000:100 import-route-targets=65000:100 interfaces=br100 route-distinguisher=65000:100 routing-mark=VRF_DEVOPS
/routing bgp instance vrf
add redistribute-connected=yes routing-mark=VRF_DEVOPS
```

Для масштабирования iBGP в сети развернут кластер Route Reflector. Роутеры, такие как R01_hki, берут на себя роль рефлекторов маршрутов. Базовая их настройка включает создание loopback-интерфейсов с уникальными Router ID, развертывание OSPF в зоне backbone для обеспечения полной связности и активацию MPLS с LDP на всех каналах между узлами. Основная задача этих устройств — ретрансляция маршрутной информации. Установленные iBGP-сессии конфигурируются с явным указанием роли Route Reflector для необходимых пиров. Такая архитектура позволяет избежать полносвязной схемы между всеми BGP-спикерами, обеспечивая при этом эффективный и контролируемый обновлениями маршрутов между всеми участниками сети.

R01_hki:
```
/system identity
set name=R01.HKI

/ip address
add address=10.20.1.2/30 interface=ether2
add address=10.20.11.1/30 interface=ether3
add address=10.20.12.2/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.2/32 interface=loopback network=10.255.255.2

/routing ospf instance
add name=inst router-id=10.255.255.2
/routing ospf area
add name=backbonev2 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev2 network=10.20.1.0/30
add area=backbonev2 network=10.20.11.0/30
add area=backbonev2 network=10.20.12.0/30
add area=backbonev2 network=10.255.255.2/32

/mpls ldp
set lsr-id=10.255.255.2
set enabled=yes transport-address=10.255.255.2
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/routing bgp instance
set default as=65000 router-id=10.255.255.2
/routing bgp peer
add name=peerSPB address-families=l2vpn,vpnv4 remote-address=10.255.255.1 remote-as=65000 update-source=loopback route-reflect=no
add name=peerLND address-families=l2vpn,vpnv4 remote-address=10.255.255.4 remote-as=65000 update-source=loopback route-reflect=yes
add name=peerLBN address-families=l2vpn,vpnv4 remote-address=10.255.255.5 remote-as=65000 update-source=loopback route-reflect=yes
/routing bgp network
add network=10.255.255.0/24
```

Как роутеры через bgp видят друг друга, а также как эндпоинты видят друг друга через vfs:

<img width="1207" height="773" alt="image" src="https://github.com/user-attachments/assets/69ad6b96-d8a6-4f07-b6bc-e464c76dd26c" />

Пропингуем пк: 

<img width="832" height="302" alt="image" src="https://github.com/user-attachments/assets/9a426040-3474-498a-a9cc-5785c848cbac" />

# Вторая часть работы:

Для перехода с L3VPN на VPLS конфигурация на граничных маршрутизаторах была изменена. Сначала выполнена отвязка ранее созданных VRF от физических интерфейсов и таблиц маршрутизации. Затем для эмуляции виртуального коммутатора второго уровня был создан bridge, к которому подключен интерфейс, ведущий к клиентскому оборудованию.

Организация L2-туннеля через MPLS-ядро была выполнена с помощью BGP VPLS. В его настройках указаны RT и RD для идентификации сервиса, а также уникальный site-id для защиты от петель. Интерфейсу VPLS был назначен IP-адрес из новой общей подсети.

Для автоматической настройки клиентов адаптированы параметры DHCP: создан новый пул адресов, соответствующий подсети VPLS, и активирован сервер на bridge-интерфейсе. В результате все конечные устройства, подключенные к разным граничным роутерам, работают в одном широковещательном домене, как если бы они были соединены одним кабелем.

R01_spb:

```
/system identity
set name=R01.SPB

/ip address
add address=10.20.1.1/30 interface=ether2
add address=192.168.10.1/24 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.1/32 interface=loopback network=10.255.255.1

/routing ospf instance
add name=inst router-id=10.255.255.1
/routing ospf area
add name=backbonev2 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev2 network=10.20.1.0/30
add area=backbonev2 network=192.168.10.0/24
add area=backbonev2 network=10.255.255.1/32

/mpls ldp
set lsr-id=10.255.255.1
set enabled=yes transport-address=10.255.255.1
/mpls ldp interface
add interface=ether2
add interface=ether3

/routing bgp instance
set default as=65000 router-id=10.255.255.1
/routing bgp peer
add name=peerHKI remote-address=10.255.255.2 address-families=l2vpn,vpnv4 remote-as=65000 update-source=loopback route-reflect=no 
/routing bgp network
add network=10.255.255.0/24

/interface bridge
add name=vpn
/interface bridge port
add interface=ether3 bridge=vpn
/interface vpls bgp-vpls
add bridge=vpn export-route-targets=65000:100 import-route-targets=65000:100 name=vpn route-distinguisher=65000:100 site-id=1
/ip address
add address=10.100.1.1/24 interface=vpn

/ip pool
add name=vpn-dhcp-pool ranges=10.100.1.100-10.100.1.254
/ip dhcp-server
add address-pool=vpn-dhcp-pool disabled=no interface=vpn name=dhcp-vpls
/ip dhcp-server network
add address=10.100.1.0/24 gateway=10.100.1.1
```

Маршрутизаторы кластера Route Reflector были адаптированы для поддержки сервиса VPLS. Их настройка свелась к обновлению BGP-пиринга: старые сессии, ориентированные на обмен VPNv4-маршрутами, были удалены, а вместо них добавлены новые с активацией адресного семейства l2vpn. Все сессии устанавливаются между loopback-интерфейсами, что обеспечивает отказоустойчивость, а в параметрах указываются атрибуты для корректного построения L2-туннелей поверх MPLS.

Этот подход позволяет использовать существующую масштабируемую BGP-инфраструктуру для распространения управляющей информации VPLS, гарантируя полную связность между всеми удаленными узлами в рамках виртуального широковещательного домена.

R01_hki:

```
/system identity
set name=R01.HKI

/ip address
add address=10.20.1.2/30 interface=ether2
add address=10.20.11.1/30 interface=ether3
add address=10.20.12.2/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.2/32 interface=loopback network=10.255.255.2

/routing ospf instance
add name=inst router-id=10.255.255.2
/routing ospf area
add name=backbonev2 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev2 network=10.20.1.0/30
add area=backbonev2 network=10.20.11.0/30
add area=backbonev2 network=10.20.12.0/30
add area=backbonev2 network=10.255.255.2/32

/mpls ldp
set lsr-id=10.255.255.2
set enabled=yes transport-address=10.255.255.2
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/routing bgp instance
set default as=65000 router-id=10.255.255.2
/routing bgp peer
add name=peerSPB address-families=l2vpn,vpnv4 remote-address=10.255.255.1 remote-as=65000 update-source=loopback route-reflect=no
add name=peerLND address-families=l2vpn,vpnv4 remote-address=10.255.255.4 remote-as=65000 update-source=loopback route-reflect=yes
add name=peerLBN address-families=l2vpn,vpnv4 remote-address=10.255.255.5 remote-as=65000 update-source=loopback route-reflect=yes
/routing bgp network
add network=10.255.255.0/24
```

Раздадим айпишники компам и в роутере:

<img width="815" height="492" alt="image" src="https://github.com/user-attachments/assets/519a225f-476a-43cf-90ce-171f20d8b0ab" />

Пропингуем ПК между друг другом: 

<img width="900" height="618" alt="image" src="https://github.com/user-attachments/assets/8b79a5b4-05a0-4db6-a77e-95ad393d8888" />

<img width="1105" height="716" alt="image" src="https://github.com/user-attachments/assets/f139aafa-8c3e-45c2-b99a-b434ea4710af" />



