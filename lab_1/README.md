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


