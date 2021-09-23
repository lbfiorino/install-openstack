# Export OpenStack VMs and Convert to VirutalBox/VMware/Hyper-V

## Requirements
qemu-img - QEMU disk image utility
```bash
# Debian/Ubuntu
apt-get install qemu-utils

#CentOS
yum install qemu-img
```
### Version used 
Ubuntu 20.04
qemu-img version 4.2.1
Supported formats: blkdebug blklogwrites blkreplay blkverify bochs cloop copy-on-read dmg file ftp ftps host_cdrom host_device http https iscsi iser luks nbd null-aio                    null-co nvme parallels qcow qcow2 qed quorum raw rbd replication sheepdog ssh throttle vdi vhdx vmdk vpc vvfat

## List intances
```bash
openstack server list
```

## Stop instance
```bash
openstack server stop myInstance
```

## Create Snapshot
```bash
openstack server image create --name myInstanceSnapshot myInstance
```

## List images
```bash
openstack image list
```

## Download image
```bash
openstack image save myInstanceSnapshot --file myInstanceSnapshot.qcow2
```

## Convert to VirtualBox
```bash
qemu-img convert -O vdi myInstanceSnapshot.qcow2 myInstanceSnapshot.vdi
```

## Convert to VMware
```bash
qemu-img convert -O vdi myInstanceSnapshot.qcow2 myInstanceSnapshot.vmdk
```

## Convert to Hyper-V
```bash
# VHD
qemu-img convert -O vpc myInstanceSnapshot.qcow2 myInstanceSnapshot.vhd

# VHDX
qemu-img convert -O vhdx myInstanceSnapshot.qcow2 myInstanceSnapshot.vhdx
```

