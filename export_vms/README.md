# Export OpenStack VMs and Convert to VirutalBox/VMware/Hyper-V

## Requirements
```bash
# Debian/Ubuntu
apt-get install qemu-utils

#CentOS
yum install qemu-img
```

## List intances
```bash
openstack server list

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

## Save image
```bash
openstack image save myInstance --file myInstance.qcow2
```

## Convert to VirtualBox
```bash
qemu-img convert -O vdi myInstance.qcow2 myInstance.vdi
```

## Convert to VMware
```bash
qemu-img convert -O vdi myInstance.qcow2 myInstance.vmdk
```

## Convert to Hyper-V
qemu-img convert -O vpc myInstance.qcow2 myInstance.vhd
