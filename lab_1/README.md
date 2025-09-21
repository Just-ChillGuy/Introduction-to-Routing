# Предисловие

Возможно, у некоторых ранее была установлена WSL. Из-за этого возможен конфликт, WSL2 использует Virtual Machine Platform и запускает собственный гипервизор (через hypervisorlaunchtype Auto), из-за чего VirtualBox видит, что VT-x занят и не может пробросить его в гостевую Ubuntu. Поэтому его нужно отключить в PowerShell:

```
wsl --unregister Ubuntu
wsl --shutdown
dism.exe /Online /Disable-Feature /FeatureName:VirtualMachinePlatform
dism.exe /Online /Disable-Feature /FeatureName:WindowsSubsystemForLinux
dism.exe /Online /Disable-Feature /FeatureName:WindowsHypervisorPlatform
bcdedit /set hypervisorlaunchtype off
```

Вот этого быть не должно:

```
hypervisorlaunchtype Auto
```

# Основная часть

Создаём виртуальную машину, как-нибудь ее называем и после её запуска выключаем.

Заходим в расположение виртуал бокса.

```
C:\Windows\System32>cd "C:\Program Files\Oracle\VirtualBox
```

Далее прописываем следующие команды: 

```
VBoxManage modifyvm "Ivan001" --hwvirtex on
```

Включаем nested paging (расширение аппаратной виртуализации):

```
VBoxManage modifyvm "Ivan001" --nestedpaging on
```

Задаём тип паравиртуализации (здесь KVM):

```
VBoxManage modifyvm "Ivan001" --paravirtprovider kvm
```

Включаем поддержку PAE (Physical Address Extension):

```
VBoxManage modifyvm "Ivan001" --pae on
```

Далее запускаем виртуалку и настраиваем её полностью.

В терминале проверяем поддержку аппаратной виртуализации (не должно выводить <0>):

```
lscpu | grep -E 'vmx|svm' || egrep -c '(vmx|svm)' /proc/cpuinfo
```

Проверяем, загружен ли KVM модуль (если предыдущие шаги сделаны успешно, то по идее всё будет ок):

```
ls -l /dev/kvm
```

Теперь скачаем установочный скрипт containerlab:

```
bash -c "$(curl -sL https://get.containerlab.dev)"
```
Установил Docker и docker-compose, включил и запустил сервис Docker при старте системы, добавил пользователя ivan001 в группу docker, чтобы можно было работать без sudo

```
sudo apt install -y docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```

Клонировал репозиторий vrnetlab из GitHub

```
cd vrnetlab
ls -a
cd mikrotik/routeros
ls -a
```

В эту папку закинул chr-6.47.9.vmdk:
```
vrnetlab/mikrotik/routeros
```

Далее захожу в свой репозиторией с lab.yaml.
Запускаю Containerlab, происходит считывание указанного файла топологии.

```
clab deploy -t lab.yaml
```

Открываем интерактивный терминал внутри контейнера clab-lab_1-PC1:

```
sudo docker exec -it clab-lab_1-PC1 sh
```

Настраиваем PC1:

```
sh configs/setup_pc1.sh
```

Проверяем:

```
ip addr
```

То же самое для PC2:

```
sudo docker exec -it clab-lab_1-PC2 sh
sh configs/setup_pc2.sh
ip addr
```

Из PC1 пингуем PC2:

```
ping 10.10.20.10
```

Если что, оно действительно проходит

Из PC2 пингуем PC1:

```
ping 10.10.10.10
```

Тоже всё проходит.

# Разбор файлов 

## lab.yaml

```
name: lab_1

topology:
  nodes:
    R1:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 10.10.10.11
      startup-config: ./configs/r1.rsc
    SW1:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 10.10.10.12
      startup-config: ./configs/sw1.rsc
    SW2:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 10.10.10.13
      startup-config: ./configs/sw2.rsc
    SW3:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 10.10.10.14
      startup-config: ./configs/sw3.rsc
    PC1:
      kind: linux
      image: alpine:latest
      binds:
        - ./configs:/configs
    PC2:
      kind: linux
      image: alpine:latest
      binds:
        - ./configs:/configs

  links:
    - endpoints: ["R1:eth2", "SW1:eth2"]
    - endpoints: ["SW1:eth3", "SW2:eth2"]
    - endpoints: ["SW1:eth4", "SW3:eth2"]
    - endpoints: ["SW2:eth3", "PC1:eth2"]
    - endpoints: ["SW3:eth3", "PC2:eth2"]

mgmt:
  network: dhcp 
  ipv4-subnet: 10.10.10.0/24
```

Топология для ContainerLab, описывающая, как развернуть тестовую сеть для лабораторной работы.

Он задаёт сеть под названием lab_1, в которой есть шесть узлов: четыре устройства RouterOS (R1, SW1, SW2, SW3) и два Linux-пк (PC1 и PC2). Для каждого роутера указан тип устройства (vr-mikrotik_ros), образ Docker (vrnetlab/mikrotik_routeros:6.47.9), IP-адрес для управления (mgmt-ipv4) и путь к конфигурационному файлу, который нужно загрузить при старте (startup-config). Для ПК указано, что они используют Linux (alpine:latest) и что каталог ./configs монтируется внутрь контейнера, чтобы можно было использовать скрипты для настройки сети.

Далее перечислены связи между интерфейсами устройств. Например, интерфейс eth2 роутера R1 соединён с интерфейсом eth2 SW1, интерфейс SW1 eth3 соединён с SW2 eth2, SW1 eth4 с SW3 eth2, SW2 eth3 с PC1 eth2 и SW3 eth3 с PC2 eth2. То есть этот блок задаёт топологию кабелей между устройствами.

В конце файла описана сеть управления (mgmt), которая создаётся на базе DHCP и использует подсеть 10.10.10.0/24. Эта сеть позволяет обращаться к каждому устройству через его mgmt-ipv4.

## r1.rsc

```
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
```

Сначала создаются два VLAN на интерфейсе ether3: vlan10 с ID 10 и vlan20 с ID 20. Эти VLAN будут использоваться для разделения сети на два логических сегмента.

Далее задаются IP-адреса для этих VLAN: vlan10 получает адрес 10.10.10.1/24, а vlan20 — 10.10.20.1/24. Это будут шлюзы для соответствующих сетей.

После этого создаются два пула IP-адресов для DHCP: для VLAN10 диапазон 10.10.10.100–10.10.10.200, для VLAN20 диапазон 10.10.20.100–10.10.20.200. Эти адреса будут выдаваться клиентам автоматически.

Затем на каждом VLAN включается DHCP-сервер, который раздаёт адреса из соответствующих пулов. Для каждой подсети также указывается шлюз (адрес VLAN-интерфейса), чтобы клиенты знали, куда отправлять трафик вне своей сети.

После настройки сетей создаётся новый пользователь newadmin с паролем newadmin и полными правами (group=full).

## setup_PC1.sh

```
#!/bin/sh
ip link add link eth2 name vlan10 type vlan id 10
ip addr add 10.10.10.10/24 dev vlan10
ip link set vlan10 up
udhcpc -i vlan10
```

Сначала создаётся VLAN-интерфейс на основе физического интерфейса eth2 с именем vlan10 и идентификатором VLAN 10 (ip link add link eth2 name vlan10 type vlan id 10). Это создаёт логический интерфейс, который «прикреплён» к физическому интерфейсу и маркирует трафик тегом VLAN 10.

Далее этому VLAN-интерфейсу назначается IP-адрес 10.10.10.10 с маской 24 (ip addr add 10.10.10.10/24 dev vlan10). Этот адрес будет использоваться компьютером в сети VLAN10.

Затем VLAN-интерфейс поднимается в активное состояние (ip link set vlan10 up), чтобы можно было передавать трафик.

Запускается DHCP-клиент udhcpc на интерфейсе vlan10 (udhcpc -i vlan10), чтобы, если настроен DHCP-сервер, компьютер мог получить динамический IP-адрес и другие параметры сети

## setup_PC1.sh

Аналогично

## sw1.rsc


```
/interface vlan
add name=vlan10_e3 vlan-id=10 interface=ether3
add name=vlan20_e3 vlan-id=20 interface=ether3
add name=vlan10_e4 vlan-id=10 interface=ether4
add name=vlan20_e5 vlan-id=20 interface=ether5
/interface bridge
add name=br_v10
add name=br_v20
/interface bridge port
add interface=vlan10_e3 bridge=br_v10
add interface=vlan10_e4 bridge=br_v10
add interface=vlan20_e3 bridge=br_v20
add interface=vlan20_e5 bridge=br_v20
/ip dhcp-client
add disabled=no interface=br_v20
add disabled=no interface=br_v10
/user add name=newadmin password=newadmin group=full
/system identity set name=SW1-Switch
```

Настраивает коммутатор SW1, создавая VLAN-интерфейсы на портах ether3, ether4 и ether5 с идентификаторами 10 и 20, затем объединяет эти VLAN-интерфейсы в два моста br_v10 и br_v20, соответствующие VLAN10 и VLAN20, подключает к ним VLAN-интерфейсы, включает DHCP-клиент на обоих мостах для автоматического получения IP-адресов, создаёт пользователя newadmin с полными правами и задаёт имя устройства SW1-Switch.

## sw2.rsc

Настраивает коммутатор SW2, создавая VLAN-интерфейсы vlan10_e3 на порту ether3 и vlan10_e4 на порту ether4 с идентификатором VLAN 10, затем объединяет эти VLAN-интерфейсы в мост br_v10, подключает к мосту оба VLAN-интерфейса, включает DHCP-клиент на мосту br_v10 для автоматического получения IP-адреса, создаёт пользователя newadmin с полными правами и задаёт имя устройства SW2-Switch.

## sw3.rsc 

```
/interface vlan
add name=vlan20_e3 vlan-id=20 interface=ether3
add name=vlan20_e4 vlan-id=20 interface=ether4
/interface bridge
add name=br_v20
/interface bridge port
add interface=vlan20_e3 bridge=br_v20
add interface=vlan20_e4 bridge=br_v20
/ip dhcp-client
add disabled=no interface=br_v20
/user add name=newadmin password=newadmin group=full
/system identity set name=SW3-Switch
```

Настраивает коммутатор SW3, создавая VLAN-интерфейсы vlan20_e3 на порту ether3 и vlan20_e4 на порту ether4 с идентификатором VLAN 20, затем объединяет эти VLAN-интерфейсы в мост br_v20, подключает к мосту оба VLAN-интерфейса, включает DHCP-клиент на мосту br_v20 для автоматического получения IP-адреса, создаёт пользователя newadmin с полными правами и задаёт имя устройства SW3-Switch.
