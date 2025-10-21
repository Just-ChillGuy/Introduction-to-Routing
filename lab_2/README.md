# Топология

```
name: lab2

topology:
    kinds:
        vr-mikrotik_ros:
            image: vrnetlab/vr-routeros:6.47.9
        linux:
            image: alpine:latest
    nodes:
        R01_msk:
            kind: vr-mikrotik_ros
            mgmt-ipv4: 192.168.50.11
            startup-config: ./configs/r1.rsc
        R02_brl:
            kind: vr-mikrotik_ros
            mgmt-ipv4: 192.168.50.12
            startup-config: ./configs/r2.rsc
        R03_frt:
            kind: vr-mikrotik_ros
            mgmt-ipv4: 192.168.50.13
            startup-config: ./configs/r3.rsc
        PC1:
            kind: linux
            binds:
              - ./configs:/configs
        PC2:
            kind: linux
            binds:
              - ./configs:/configs
        PC3:
            kind: linux
            binds:
              - ./configs:/configs
    links:
        - endpoints: ["R01_msk:eth2", "R02_brl:eth2"]
        - endpoints: ["R01_msk:eth3", "R03_frt:eth3"]
        - endpoints: ["R01_msk:eth4", "PC1:eth2"]
        - endpoints: ["R02_brl:eth3", "R03_frt:eth2"]
        - endpoints: ["R02_brl:eth4", "PC2:eth2"]
        - endpoints: ["R03_frt:eth4", "PC3:eth2"]

mgmt:
    network: mgmt-net
    ipv4-subnet: 192.168.50.0/24
```

networklab.clab.yaml описывает топологию виртуальной сети для лабораторной работы в ContainerLab. Он задаёт имя лаборатории, определяет типы устройств, которые будут использоваться, и конкретные узлы сети с их настройками. В файле указываются три маршрутизатора, представляющие офисы компании в Москве, Берлине и Франкфурте, и три персональных компьютера, подключённых к своим маршрутизаторам. Для маршрутизаторов задаются IP-адреса в сети управления, чтобы можно было подключаться к ним с хоста или других контейнеров, а также указываются стартовые конфигурации, которые ContainerLab применяет при запуске контейнеров. Для ПК создаются контейнеры на базе Alpine Linux с доступом к локальной папке с конфигурациями, что позволяет им получать настройки через DHCP и взаимодействовать с сетью. В файле также определяются соединения между интерфейсами маршрутизаторов и между маршрутизаторами и ПК, формируя физические линии связи, по которым будут передаваться данные. Кроме того, создаётся сеть управления, в которой назначается подсеть для управляющих IP-адресов контейнеров, что обеспечивает возможность контроля и взаимодействия между всеми узлами топологии. В результате этот файл полностью описывает структуру сети, её компоненты, взаимосвязи и необходимые настройки для развертывания рабочей лабораторной сети с тремя офисами и подключёнными к ним клиентскими ПК.

```
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
/system identity
set name=R01_msk
/user set admin password=192856
```
r1.rsc конфигурация на маршрутизаторе R01 настраивает его как центральный узел сети для офиса в Москве. Сначала создаётся пул IP-адресов для DHCP, из которого маршрутизатор будет выдавать адреса клиентским устройствам в локальной сети, и на соответствующем интерфейсе активируется DHCP-сервер. Затем задаются IP-адреса для трёх интерфейсов: один адрес предназначен для локальной сети офиса, а два других — для соединений с офисами в Берлине и Франкфурте. После этого настраивается подсеть DHCP с указанием шлюза, чтобы ПК, подключённые к маршрутизатору, могли автоматически получать адреса и корректно маршрутизировать трафик. Далее добавляются статические маршруты, которые указывают, через какие интерфейсы пакеты должны идти к офисам в Берлине и Франкфурте, обеспечивая связь между всеми офисами. В конце конфигурации задаётся имя устройства как R01_msk, чтобы легко идентифицировать маршрутизатор в сети, и меняется пароль администратора для безопасного доступа к устройству.

```
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
/system identity
set name=R01_msk
/user set admin password=192856
```

r2:

```
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
/system identity
set name=R02_brl
/user set admin password=192856
```

r3:

```
/ip pool
add name=dhcp_pool_frt ranges=192.168.3.3-192.168.3.200
/ip dhcp-server
add address-pool=dhcp_pool_frt disabled=no interface=ether5 name=dhcp_frt
/ip address
add address=20.20.20.2/30 interface=ether3
add address=30.30.30.1/30 interface=ether4
add address=192.168.3.2/24 interface=ether5
/ip dhcp-server network
add address=192.168.3.0/24 dns-server=8.8.8.8 gateway=192.168.3.2
/ip route
add distance=1 dst-address=192.168.1.0/24 gateway=30.30.30.2
add distance=1 dst-address=192.168.2.0/24 gateway=20.20.20.1
/system identity
set name=R03_frt
/system identity
set name=R03_frt
/user set admin password=192856
```
Настройка пк:

```
#!/bin/sh
udhcpc -i eth2
ip route del default via 192.168.50.1 dev eth0
```

Сборка контейнера:

```
sudo containerlab deploy -t networklab.clab.yaml
```

Залезаем в r1:

```
ssh admin@192.168.50.11
```


