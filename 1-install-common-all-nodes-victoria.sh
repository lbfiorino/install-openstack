#/bin/bash

#--------------------------------------------------------------------------------
# Sistema Operacional: CentOS 8
# Openstack release: VICTORIA
#
# INSTALA REQUISITOS COMUNS A TODOS OS NOS
#
#--------------------------------------------------------------------------------

##### AJUSTAR OS HOSTS E IPs CONFORME NECESSÁRIO #####

CONTROLLER_HOSTNAME="openstack-controller"
CONTROLLER_IP="192.168.0.200"

COMPUTE01_HOSTNAME="openstack-compute01" 
COMPUTE01_IP="192.168.0.201"


#--------------------------------------------------------------------------------

# 1.2 REQUISITOS BASICOS

dnf install -y epel-release
dnf config-manager --enable PowerTools

# Requisitos Kolla-Ansible
dnf install -y python3-devel libffi-devel gcc openssl-devel python3-libselinux

# (Opcional)
#dnf group install -y "Development Tools"

# Utilitários
dnf install -y git python3-pip wget curl telnet tcpdump net-tools htop dstat nano
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade setuptools


# 1.3 DESABILITAR NETWORKMANAGER E HABILITAR NETWORK-SCRIPTS
dnf install -y network-scripts
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl enable network.service
systemctl start network.service

# 1.4 DESABILITAR FIREWALLD
systemctl stop firewalld.service
systemctl disable firewalld.service

# 1.5 DESABILITAR SELINUX
/usr/sbin/setenforce 0
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config


# 1.6 ADICIONA HOSTS NO /ETC/HOSTS
echo -e "
# controller
$CONTROLLER_IP			$CONTROLLER_HOSTNAME

# compute01
$COMPUTE01_IP			$COMPUTE01_HOSTNAME" >> /etc/hosts


# 1.8 ADICIONA USUÁRIO STACK
adduser stack
echo "stack" | passwd --stdin stack


# 1.9 ADICIONA USUÁRIO STACK NO SUDOERS
echo "stack	ALL=(ALL) ALL" >> /etc/sudoers


# 1.10 INSTALA ANSIBLE NA VERSÃO  2.9
cd /root
git clone https://github.com/ansible/ansible.git -b stable-2.9
cd ansible
pip3 install .


# 1.11 INSTALA DOCKER
cd /root
curl -sSL https://get.docker.io | bash


# 1.12 CONFIGURAÇÃO DO KOLLA E DOCKER
# Criar o arquivo de configuração do kolla no systemd:
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

echo "\n\n
---------------------------------------------------------------
ATENCAO!

1.7 CONFIGURAR A INTERFACE DE REDE PROVIDER SEM IP.

Editar o arquivo /etc/sysconfig/network-scripts/ifcfg-enp0s8
e ajustar os parâmetros de acordo com o exemplo abaixo.

TYPE=\"Ethernet\"
BOOTPROTO=\"none\"
NAME=\"enp0s8\"
UUID=\"aa48dec3-17e1-46f8-a443-c9c1c939ec0d\"
DEVICE=\"enp0s8\"
ONBOOT=\"yes\"

Reiniciar a máquina para aplicar as alterações.
---------------------------------------------------------------
"


