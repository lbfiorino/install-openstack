#/bin/bash

#--------------------------------------------------------------------------------
# Sistema Operacional: CentOS 8
# Openstack release: VICTORIA
#
# INSTALA REQUISITOS DO CONTROLLER
#
#--------------------------------------------------------------------------------


# 2.1 INSTALA KOLLA
cd /root
git clone https://github.com/openstack/kolla -b stable/victoria
cd kolla
pip3 install .

# 2.2 Instala KOLLA-ANSIBLE
cd /root
git clone https://github.com/openstack/kolla-ansible -b stable/victoria
cd kolla-ansible
pip3 install .

echo "\n\n"
echo "---------------------------------------------------------------------"
echo "GERAÇÃO DA CHAVE SSH E INSERÇÃO NOS HOSTS"
echo "Apenas tecle enter e informe a senha dos usuarios quando solicitado."
echo "---------------------------------------------------------------------"
echo "\n\n"
# 2.3 GERAÇÃO DA CHAVE SSH E INSERÇÃO NOS NÓS PARA OS USUÁRIOS ROOT E STACK
# Root user
echo "Chave para o usuario Root\n\n"
cd /root
ssh-keygen
ssh-copy-id root@openstack-controller
ssh-copy-id root@openstack-compute01

echo "Chave para o usuario Stack\n\n"
# Stack user
sudo -H -u stack bash -c 'ssh-keygen; ssh-copy-id stack@openstack-controller; ssh-copy-id stack@openstack-compute01' 


# 2.4 CONFIGURAÇÃO DO INVENTÁRIO DO KOLLA
cd /root
# Copia arquivo globals.yaml para /etc/kolla/globals.yaml
cp -r ./kolla-ansible/etc/kolla /etc/kolla/
# Copia os arquivos de inventário (all-in-one, multinode) na raiz do diretório /root
cp ~/kolla-ansible/ansible/inventory/* .


# 2.5 GERACAO DAS SENHAS DO KOLLA
cd /root
cd ./kolla-ansible/tools
python3 generate_passwords.py


# 2.6 CONFIGURACAO DOS HOSTS PARA O ANSIBLE
mkdir /etc/ansible
tee /etc/ansible/hosts <<-'EOF'
[controller]
openstack-controller

[compute]
openstack-compute01
EOF


# 2.12 INSTALA OS CLIENTES DO OPENSTACK
# Do Python PyPI
pip3 install python-openstackclient
pip3 install gnocchiclient
# OU
# Do repositório CentOS
#dnf install -y centos-release-openstack-victoria
#dnf upgrade -y
#dnf install -y python-openstackclient



cd /root

echo "
-----------------------------------------------------------------------------------------------------------------------------------------------
PROXIMOS PASSOS NO CONTROLADOR:

2.7 Alterar as senhas necessárias no arquivo /etc/kolla/passwords.yml
        keystone_admin_password: senha-desejada


2.8 Configurar o arquivo /etc/kolla/globals.yml

        kolla_base_distro: \"centos\"
        kolla_install_type: \"source\"
        openstack_release: \"victoria\"
        # kolla_internal_vip_address: IP não utilizado na rede
        kolla_internal_vip_address: \"192.168.0.199\"
        network_interface: \"enp0s3\"
        neutron_external_interface: \"enp0s8\"

        enable_ceilometer: \"yes\"
        enable_gnocchi: \"yes\"
        enable_neutron_provider_networks: \"yes\"
        enable_redis: \"yes\"


        Nota:

        Em ambiente virtualizado mudar o tipo de virtualização para QEMU:
        
        nova_compute_virt_type: \"qemu\"


2.9 Configurar o arquivo /root/multinode

	[control]
	localhost

	[network]
	localhost

	[compute]
	openstack-compute01 ansible_ssh_user=stack ansible_sudo_pass=stack ansible_become=True ansible_private_key_file=/home/stack/.ssh/id_rsa

	[monitoring]
	localhost

	[storage]
	#storage01


2.10 Checar a configuração do multinode com o ansible

	ansible -i multinode all -m ping


2.11 Revisão da configuração do kolla-ansible e deploy

	Para Development:
	cd /root/kolla-ansible/tools/
	./kolla-ansible -i ../../multinode bootstrap-servers
	./kolla-ansible -i ../../multinode prechecks
	./kolla-ansible -i ../../multinode pull
	./kolla-ansible -i ../../multinode deploy


	Para Deployment:
	cd /root
	kolla-ansible -i multinode bootstrap-servers
	kolla-ansible -i multinode prechecks
	kolla-ansible -i multinode pull
	kolla-ansible -i multinode deploy

-----------------------------------------------------------------------------------------------------------------------------------------------
"
