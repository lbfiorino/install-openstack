# Export OpenStack VMs and Convert to VirutalBox/VMware/Hyper-V

## Requirements
qemu-img - QEMU disk image utility
```bash
# Debian/Ubuntu
apt-get install qemu-utils

#CentOS
yum install qemu-img
```

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
openstack image save myInstanceSnapshot --file /var/myInstanceSnapshot.qcow2
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
qemu-img convert -O vpc myInstanceSnapshot.qcow2 myInstanceSnapshot.vhd
