# Instalação do OpenStack com Kolla-Ansible

OpenStack Release: **Victoria**

[Documentação Kolla-Ansible](https://docs.openstack.org/kolla-ansible/victoria/)

## Limitações
- A instalação não cria automaticamente as redes dentro do OpenStack. A configuração deve ser feita de forma manual no Horizon ou pela linha de comando;  
 
- Acesso a API por HTTP. Requer estudos e testes para habilitar HTTPS.


## Requisitos mínimos de hardware
- 2 Interfaces de rede
- 8GB Memória RAM
- 40GB Espaço em disco

## Sistema Operacional
- CentOS 8 
    - Instalação mínima
    - Release 8.2.2004 utilizada no momento da instalação
- Sistema de arquivos XFS


## Topologia multinode OpenStack
![Topologia](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/topologia.png)


## Infraestrutura utilizada
A infraestrutura foi configurada em um ambiente virtual utilizando o VirtualBox em um host com duas interfaces de rede físicas.  

As máquinas virtuais (*controller* e *compute01*) foram configuradas com duas interfaces de rede em modo bridge, uma na rede interna (*management*) e outra na rede do roteador da operadora (*provider*). 
 
:warning: Nota:
>Não foi utlizado Vlan nas redes.


### Configuração da rede

- Nomes das interfaces devem ser iguais nos nós

- Interfaces:
    - **enp0s3**: *Management Network* - 192.168.0.0/24 (Rede Interna)

    - **enp0s8**: *Provider Network* - 192.168.254.0/24 (Roteador da Operadora)

- IP dos Hosts: 
    - Nó Controlador: **openstack-controller**
        - *enp0s3*: 192.168.0.200/24
        - *enp0s8*: SEM IP

    - Nó de Computação: **openstack-compute01**
        - *enp0s3*: 192.168.0.201/24
        - *enp0s8*: SEM IP

-  **Diagrama da rede:**

![Infraestrutura](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/infraestrutura.svg)

-  **Diagrama da rede no ambiente virtual:**

![Infraestrutura-Virtual](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/infra-virtual.svg)

:warning: Notas:
>- No VirtualBox, configurar o Modo Promíscuo nas interfaces de rede das VMs para "Permitir Tudo".
>- Em caso de problema no *pull* das imagens do docker, verificar o MTU da rede.


## 1. Procedimentos comuns a TODOS OS NÓS
:warning: Nota:
> Todo o processo de instalação teve como base o usuário *root* e o diretório */root/*

### 1.1 Atualizar o sistema operacional

```bash
dnf -y upgrade
reboot
```


### 1.2 Requisitos básicos

```bash
dnf install -y epel-release
dnf config-manager --enable PowerTools
dnf -y upgrade

## Requisitos Kolla-Ansible
dnf install -y python3-devel libffi-devel gcc openssl-devel python3-libselinux

# (Opcional)
#dnf group install -y "Development Tools"

# Utilitários
dnf install -y git python3-pip wget curl telnet tcpdump net-tools htop dstat nano

python3 -m pip install --upgrade pip
python3 -m pip install --upgrade setuptools
```


### 1.3 Desabilitar NetworkManager e habilitar network-scripts
```bash
dnf install -y network-scripts

systemctl stop NetworkManager.service
systemctl disable NetworkManager.service

systemctl enable network.service
systemctl start network.service
```


### 1.4 Desabilitar Firewalld
```
systemctl stop firewalld.service
systemctl disable firewalld.service
```


### 1.5 Desabilitar SELINUX
```bash
setenforce 0
```
Editar o arquivo */etc/selinux/config* e alterar o parametro SELINUX para *disabled*.
```
SELINUX=disabled
```

### 1.6 Adicionar hosts no */etc/hosts*
```bash
# controller
192.168.0.200           openstack-controller

# compute01
192.168.0.201           openstack-compute01
```


### 1.7 Configurar a interface da rede provider SEM IP

Editar o arquivo */etc/sysconfig/network-scripts/ifcfg-enp0s8* e ajustar os parâmetros de acordo com o exemplo abaixo.
```bash
TYPE="Ethernet"
BOOTPROTO="none"
NAME="enp0s8"
UUID=<UUID>
DEVICE="enp0s8"
ONBOOT="yes"
```

Reiniciar a máquina para aplicar as alterações.

### 1.8 Criar o usuário stack
```bash
adduser stack
#Senha: stack
echo "stack" | passwd --stdin stack
```
 
### 1.9 Adicionar o usuário stack no sudoers
Adicionar a linha abaixo no final do arquivo */etc/sudoers*
```
stack	ALL=(ALL) ALL
```


### 1.10 Instalar Ansible na versão 2.9
```bash
cd /root
git clone https://github.com/ansible/ansible.git -b stable-2.9
cd ansible
pip3 install .
```


### 1.11 Instalar Docker
```bash
cd /root
curl -sSL https://get.docker.io | bash
```


### 1.12 Configuração do kolla e docker
Criar o arquivo de configuração do kolla no systemd:
```bash
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker
```


## 2. Procedimentos específicos no CONTROLADOR
:warning: Nota:
> Novamente, todo o processo de instalação teve como base o usuário *root* e o diretório */root/*

### 2.1 Instalar Kolla
```bash
cd /root
git clone https://github.com/openstack/kolla -b stable/victoria
cd kolla
pip3 install .
```


### 2.2 Instalar Kolla-Ansible
```bash
cd /root
git clone https://github.com/openstack/kolla-ansible -b stable/victoria
cd kolla-ansible
pip3 install .
```


### 2.3 Geração da chave ssh e inserção nos nós para os usuários *root* e *stack*
Para o usuário *root*:
```bash
cd /root
ssh-keygen
ssh-copy-id root@openstack-controller
ssh-copy-id root@openstack-compute01
```
Para o usuário *stack*:
```bash
# Mudar para o usuário stack
su - stack
ssh-keygen
ssh-copy-id stack@openstack-controller
ssh-copy-id stack@openstack-compute01
# Sair do usuário stack
exit
```


### 2.4 Configuração do kolla
Copiar os arquivos:
- *globals.yml* para */etc/kolla/globals.yml*
- *passwords.yml* para */etc/kolla/passwords.yml*
- *multinode* para */root/*
```bash
cd /root

# Copia os arquivos globals.yml e passwords.yml para /etc/kolla/
cp -r ./kolla-ansible/etc/kolla /etc/kolla/

# Copia os arquivos de inventário (all-in-one, multinode) na raiz do diretório /root
cp ~/kolla-ansible/ansible/inventory/* .
```


### 2.5 Geração das senhas do kolla
```bash
cd /root/kolla-ansible/tools
python3 generate_passwords.py
```


### 2.6 Configuração dos hosts para o ansible
Criar o arquivo */etc/ansible/hosts* com o seguinte conteúdo.
```
[controller]
openstack-controller

[compute]
openstack-compute01
```

### 2.7 Alterar as senhas necessárias no arquivo */etc/kolla/passwords.yml*
```bash
# Senha do usuário admin para acesso ao Horizon
keystone_admin_password: keystoneadmin
```


### 2.8 Configurar o arquivo */etc/kolla/globals.yml*
```bash
kolla_base_distro: "centos"
kolla_install_type: "source"
openstack_release: "victoria"
# kolla_internal_vip_address: IP não utilizado na rede
kolla_internal_vip_address: "192.168.0.199"
network_interface: "enp0s3"
neutron_external_interface: "enp0s8"

enable_ceilometer: "yes"
enable_gnocchi: "yes"
enable_neutron_provider_networks: "yes"
enable_redis: "yes"
```
:warning: Nota:
> Em ambiente virtualizado mudar o tipo de virtualização para QEMU:  
>`nova_compute_virt_type: "qemu"`


### 2.9 Configurar o arquivo */root/multinode*

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


### 2.10 Checar a configuração do multinode com o ansible
	ansible -i /root/multinode all -m ping


### 2.11 Revisão da configuração do kolla-ansible e deploy
Foram usados os comandos para *development*.
```bash
# For development:
cd /root/kolla-ansible/tools/
./kolla-ansible -i ../../multinode bootstrap-servers
./kolla-ansible -i ../../multinode prechecks
./kolla-ansible -i ../../multinode pull
./kolla-ansible -i ../../multinode deploy

# OU

# For deployment or evaluation:
#cd /root
#kolla-ansible -i multinode bootstrap-servers
#kolla-ansible -i multinode prechecks
#kolla-ansible -i multinode pull
#kolla-ansible -i multinode deploy
```


### 2.12 Instalar os clientes do OpenStack
Os clientes foram instalados via Python.
```bash
# Do Python PyPI
pip3 install python-openstackclient
pip3 install gnocchiclient

# OU

# Do repositório CentOS
#dnf install -y centos-release-openstack-victoria
#dnf upgrade -y
#dnf install -y python-openstackclient
```

### 2.13 Acessar o Horizon

URL: `http://192.168.0.200`  

Usuário: `admin`  
&nbsp;&nbsp;Senha: `keystoneadmin`


### 2.14 Tunning Ansible (Opcional)
Para melhores resultados, realizar a seguinte configuração do Ansible antes do item 2.11 (verificação da configuração e *deploy*).

Criar o arquivo */etc/ansible/ansible.cfg* com o conteúdo abaixo.

```bash
[defaults]
host_key_checking=False
pipelining=True
forks=100
```
:warning: Nota:
>Esta configuração não foi realizada na instalação

## 3. Scripts para automatizar parte dos processos

Os scripts a seguir foram escritos para automatizar ao máximo o processo de instalação.

- *1-install-common-all-nodes-victoria.sh*
- *2-install-controller-victoria.sh*

### 3.1 Script *1-install-common-all-nodes-victoria.sh* (para todos os nós)
Este script realiza os procedimentos comuns a todos nós, **exceto** os itens **1.1** (atualização do SO) e **1.7** (configuração da interface da rede *provider*), pois são processos que necessitam de reinicialização na máquina

A configuração da interface de rede *provider* pode ser feita após a execução do script, e em seguida o host deve ser reiniciado.

Caso os IPs e *hostnames* sejam diferentes, alterar as seguintes variáveis no início do script.

```bash
CONTROLLER_HOSTNAME="openstack-controller"
CONTROLLER_IP="192.168.0.200"

COMPUTE01_HOSTNAME="openstack-compute01" 
COMPUTE01_IP="192.168.0.201"
```

### 3.2 Script *2-install-controller-victoria.sh* (para o controlador)
Este script realiza alguns procedimentos específicos no host controlador. São executados por este script os itens **2.1 ao 2.6**, e o item **2.12**.

**Deve** ser executado após o script *1-install-common-all-nodes-victoria.sh*.


## 4. Para adicionar outros Nós de Computação

Os nomes das interfaces de rede devem ser iguais aos demais nós.

Host: **openstack-compute02**
- Interface **enp0s3**: 192.168.0.202/24 (*Management*)  
- Interface **enp0s8**: 192.168.254.202/24 (*Provider*)

Seguir os procedimentos do item 1, comuns a todos os nós.

No controlador, exportar as chaves SSH (usuários *root* e *stack*) para o host *openstack-compute02.*, conforme o item 2.3

No controlador, adicionar o host *openstack-compute02* nos arquivos abaixo dentro da chave **[compute]**. Itens 2.6 e 2.9 respectivamente.
- */etc/ansible/hosts*
- */root/multinode*

Executar os comandos abaixo no controlador com o usuário *root*.
```bash
cd /root
cd ./kolla-ansible/tools/
./kolla-ansible -i ../../multinode deploy --limit openstack-compute02
```

## 5. Criação das redes no Horizon

### 5.1 Rede provider
Apenas administradores podem criar redes provider.
A rede provider deve ter os seguintes parâmetros:  

- Provider Network Type: `Flat`  
- Physical Network: `physnet1`
    
`physnet1` é o nome padrão para as redes do tipo *flat* que o Kolla-Ansible cria no Neutron. Esse parâmetro pode ser encontrado no arquivo `/etc/kolla/neutron-server/ml2_conf.ini`: 
```bash
[ml2_type_flat]
flat_networks = physnet1
```
:warning: Nota:
> Caso o Horizon não crie a rede informando todas as informações das abas (*Network*, *Subnet*, *Subnet Details*), desmarque a opção `Create Subnet` e crie a subnet depois.

![Provider-Network](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-provider-network.png)


![Provider-Subnet](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-provider-subnet.png)

Na subnet da rede provider, o parâmetro `Allocation Pools` é utlizadao pelo DHCP e para fornecer Floating IPs. O Floating IP funciona mesmo com o DHCP desabilitado, bastando informar o range de IPs.

![Provider-Subnet-Details](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-provider-subnet-details.png)


### 5.2 Redes privadas

As redes internas (privadas) podem ser criadas pelos usuários, dentro dos projetos.  

Ao criar uma rede dentro do projeto, não é exibida a opção  `Provider Network Type`. Por padrão a rede é criada do tipo `VXLAN`, e o OpenStack atribui automaticante o `Segmentation ID`.

![Private-Network](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-private-network.png)


![Private-Subnet](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-private-subnet.png)

![Private-Subnet-Details](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-private-subnet-details.png)


## 7. Grupos de Segurança
A instalação cria apenas um grupo de segurança com o nome `default`. Este grupo possiu regras apenas para tráfego de saída das máquinas virtuais.
