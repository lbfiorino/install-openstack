# Export OpenStack VMs and Convert to VirtualBox/VMware/Hyper-V

On VirtualBox/VMware/Hyper-V, create a VM and use the converted disk.

Converting between image formats: https://docs.openstack.org/image-guide/convert-images.html

## Requirements
qemu-img - QEMU disk image utility
```bash
# Debian/Ubuntu
apt-get install qemu-utils

#CentOS
yum install qemu-img
```
### Versions used 
- Ubuntu 20.04  
- qemu-img 4.2.1  


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
:warning: Must have enough free RAM to read the image.
```bash
# Get image disk format
openstack image show -c disk_format myInstanceSnapshot

# Assuming the disk format is qcow2.
openstack image save myInstanceSnapshot --file myInstanceSnapshot.qcow2
```

### Solution 1 - Openstack deployed with Kolla-Ansible:
Copy image from glance docker container.
```
# Copy image
# Assuming the disk format is qcow2.
docker cp glance_api:/var/lib/glance/images/{IMAGE_ID} /var/tmp/myInstanceSnapshot.qcow2
```

## Convert to VirtualBox
```bash
qemu-img convert -O vdi myInstanceSnapshot.qcow2 myInstanceSnapshot.vdi
```

## Convert to VMware
```bash
qemu-img convert -O vmdk myInstanceSnapshot.qcow2 myInstanceSnapshot.vmdk
```

## Convert to Hyper-V
```bash
# VHD
qemu-img convert -O vpc myInstanceSnapshot.qcow2 myInstanceSnapshot.vhd

# VHDX
qemu-img convert -O vhdx myInstanceSnapshot.qcow2 myInstanceSnapshot.vhdx
```

