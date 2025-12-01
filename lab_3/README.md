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
