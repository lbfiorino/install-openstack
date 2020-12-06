# Instalação do OpenStack com Kolla-Ansible  :cloud:

### OpenStack Release: Victoria

[OpenStack Releases](https://releases.openstack.org/)

[Documentação Kolla-Ansible](https://docs.openstack.org/kolla-ansible/victoria/)

[Kolla-Ansible Tips and Tricks](https://docs.openstack.org/kolla-ansible/victoria/user/operating-kolla.html#tips-and-tricks)

[Ceilometer Release Notes](https://docs.openstack.org/releasenotes/ceilometer/)


Diretórios do repositório:  
- `arquivos-conf`- contém os arquivos de configuração utilizados na instalação
- `imagens` - contém os diagramas de rede da documentação


## Limitações
- A instalação não cria automaticamente as redes dentro do OpenStack. A configuração deve ser feita de forma manual no Horizon ou pela linha de comando;  

- Acesso a API por HTTP.


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
>
>- No Hyper-V é necessário habilitar a falsificação de endereço MAC (MAC Spoofing) nas interfaces das máquinas virtuais que estão na rede *provider*.
>
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

# compute
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


### 1.12 Configuração do Docker para o Kolla
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
- `globals.yml` para `/etc/kolla/globals.yml`
- `passwords.yml` para `/etc/kolla/passwords.yml`
- `multinode` para `/root/`
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
No arquivo `/etc/kolla/globals.yml`, alterar os parâmetros abaixo.
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
:warning: Notas:
>- Em ambiente virtualizado mudar o tipo de virtualização para QEMU:  
>`nova_compute_virt_type: "qemu"`  
>
>- O parâmetro `kolla_internal_vip_address` requer um **IP não utilizado** na rede. Este IP será o de acesso a API. O Kolla-Ansible não aceitou colocar o mesmo IP da interface interna.
>
>- Os valores padrões dos outros parâmetros estão descritos nas linhas comentadas do arquivo.


### 2.9 Configurar o arquivo */root/multinode*
No arquivo `/root/multinode`, configurar os grupos de hosts conforme abaixo. Os demais não são alterados.

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

:warning: Nota:
>A instalação não utilizou storage, por isso o host `storage01` foi comentado e o módulo cinder não foi instalado.


### 2.10 Checar a configuração do multinode com o ansible
	ansible -i /root/multinode all -m ping


### 2.11 Revisão da configuração do kolla-ansible e deploy
Foram usados os comandos para `development`.

Para melhores resultados, o item **2.14 Tunning Ansible** mostra alguns parâmetros de performance do Ansible, que devem ser configurados antes de executar os comandos abaixo.

:warning: **ATENÇÃO:** Caso seja necessário habilitar outros módulos, leia o **item 8** antes de realizar o *deploy*. 

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
:warning: Nota:
> - Para evitar conflitos, instalar todos os clientes a partir do mesmo repositório. Todos via python ou todos via dnf.
> - Caso necessário, remover um cliente instalado de um repositório para reinstalar a partir de outro repositório.


### 2.13 Acessar o Horizon

URL: `http://192.168.0.200`  

Usuário: `admin`  
&nbsp;&nbsp;Senha: `keystoneadmin`


### 2.14 Tunning Ansible (Opcional)
Para melhores resultados, realizar a seguinte configuração do Ansible antes do item 2.11 (revisão da configuração e *deploy*).

Criar o arquivo `/etc/ansible/ansible.cfg` com o conteúdo abaixo.

```bash
[defaults]
host_key_checking=False
pipelining=True
forks=100
```
A documentação dos parâmentros pode ser encontrada no [arquivo de exemplo do ansible no github](https://github.com/ansible/ansible/blob/stable-2.9/examples/ansible.cfg).

:warning: Nota:
>Esta configuração **não foi realizada** na instalação


## 3. Scripts para automatizar parte dos processos

Os scripts a seguir foram escritos para automatizar ao máximo o processo de instalação.

- `1-install-common-all-nodes-victoria.sh`
- `2-install-controller-victoria.sh`


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

**Deve ser executado após** o script `1-install-common-all-nodes-victoria.sh`.


## 4. Criação das redes no Horizon


### 4.1 Rede provider
Apenas administradores podem criar redes provider.
A rede provider deve ter os seguintes parâmetros:  

- Provider Network Type: `Flat`  
- Physical Network: `physnet1`
    
`physnet1` é o nome padrão para as redes do tipo *flat* que o Kolla-Ansible cria no Neutron. Esse parâmetro pode ser encontrado no arquivo `/etc/kolla/neutron-server/ml2_conf.ini`: 
```bash
[ml2_type_flat]
flat_networks = physnet1
```
O mapeamento da `physnet1` para a `br-ex` está no arquivo `/etc/kolla/neutron-openvswitch-agent/openvswitch_agent.ini`:
```bash
[ovs]
bridge_mappings = physnet1:br-ex
```

Que por sua vez, a `br-ex` está conectada na interface `enp0s8` quando foi atribuída no `globals.yml` através do parâmetro `neutron_external_interface: "enp0s8"`

A bridge `br-ex:enp0s8` está no openvswitch e pode ser verificada com os seguintes comandos:

```bash
docker exec -it openvswitch_vswitchd bash
ovs-vsctl show
```
Bridge `br-ex` exibida pelo comando `ovs-vsctl show`:
```bash
Bridge br-ex
    Controller "tcp:127.0.0.1:6633"
        is_connected: true
    fail_mode: secure
    datapath_type: system
    Port phy-br-ex
        Interface phy-br-ex
            type: patch
            options: {peer=int-br-ex}
    Port br-ex
        Interface br-ex
            type: internal
    Port enp0s8
        Interface enp0s8
```


:warning: Notas:
>- Para usuários sem privilégios de administrador possam utilizar a rede provider, é necessário marcar a opção `Shared`.
>
>- Caso o Horizon não crie a rede informando todas as informações das abas (*Network*, *Subnet*, *Subnet Details*), desmarque a opção `Create Subnet` e crie a subnet depois.


Capturas de tela:

![Provider-Network](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-provider-network.png)


![Provider-Subnet](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-provider-subnet.png)


![Provider-Subnet-Details](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-provider-subnet-details.png)


### 4.2 Redes privadas

As redes internas (privadas) podem ser criadas pelos usuários, dentro dos projetos (**Recomendado**).  

Ao criar uma rede dentro do projeto, não é exibida a opção  `Provider Network Type`. Por padrão a rede é criada do tipo `VXLAN`, e o OpenStack atribui automaticante o `Segmentation ID`.

Capturas de tela:

![Private-Network](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-private-network.png)


![Private-Subnet](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-private-subnet.png)

![Private-Subnet-Details](https://raw.githubusercontent.com/lbfiorino/install-openstack/main/imagens/horizon-private-subnet-details.png)


## 5. Roteadores e Instâncias
Com as redes criadas, é preciso criar um roteador para permitir a comunicação entre as redes.  

Posteriormente, pode-se criar as instâncias (máquinas virtuais).


## 6. Grupos de Segurança
A instalação cria apenas um grupo de segurança com o nome `default`. Este grupo possiu regras apenas para tráfego de saída das máquinas virtuais.


## 7. IPs Flutuantes

Na subnet da rede provider, o parâmetro `Allocation Pools` é utlizadao pelo DHCP e para fornecer os `Floating IPs`.  

O Floating IP funciona mesmo com o DHCP desabilitado, bastando informar o range de IPs.


## 8. Módulos
Os módulos do OpenStack podem ser habilitados após o *deploy*, porém será baixada a imagem do docker mais recente do módulo para a release utilizada (neste caso Victoria).

**É recomendado** habilitar e configurar todos os módulos necessários antes do *deploy* (item 2.11), a fim de evitar a utilização de imagens docker com versões muitos distantes uma das outras, o que pode ocasionar problemas de compatibilidade entre os módulos. 

Para habilitar um módulo após o *deploy* do ambiente, basta descomentar a linha referente ao módulo no arquivo `/etc/kolla/globals.yml`, alterar o valor do parâmetro para `yes` e executar o comando para reconfigurar o ambiente. 

**Exemplo:** Habilitar Grafana após o *deploy*.

Editar o arquivo `/etc/kolla/globals.yml`:
```bash
#enable_grafana: "no"
enable_grafana: "yes"
```
Em seguida executar o comando para reconfigurar o ambiente:
```bash
# For development:
cd /root/kolla-ansible/tools/
./kolla-ansible -i ../../multinode reconfigure
```


### 8.1 Ceilometer / Gnocchi - Default Archive Policy

Por padrão o a política de arquivo (*Archive Policy*) do Ceilometer é `low`. Para alterar a política para `high`, deve-se criar os arquivos de configuração `pipeline.yaml` e `polling.yaml` no diretório `/etc/kolla/config/ceilometer` seguindo os passos abaixo.

- Criar o diretório `/etc/kolla/config/ceilometer`:
    ```bash
    mkdir -p /etc/kolla/config/ceilometer
    ```

- Criar o arquivo `/etc/kolla/config/ceilometer/pipeline.yaml`:  
Este arquivo pode ser obtido [neste link](https://github.com/openstack/ceilometer/blob/stable/victoria/ceilometer/pipeline/data/pipeline.yaml) ou no diretório `arquivos-conf/ceilometer/` deste repositório.   
Editar o arquivo e alterar o endereço do Gnocchi no `publishers:` para:  
    ```bash
    #- gnocchi://
    - gnocchi://?archive_policy=high
    ```
- Criar o arquivo `/etc/kolla/config/ceilometer/polling.yaml`:  
Este arquivo pode ser obtido [neste link](https://github.com/openstack/ceilometer/blob/stable/victoria/etc/ceilometer/polling.yaml) ou no diretório `arquivos-conf/ceilometer/` deste repositório.   
Editar o arquivo e alterar o parâmetro `interval:` para `1` segundo:  
    ```bash
    #interval: 300
    interval: 1
    ```

Após a criação dos arquivos, realizar o *deploy* no item 2.11 ou, caso o OpenStack já esteja operacional, realizar a reconfiguração com o comando abaixo.
```bash
# For development:
cd /root/kolla-ansible/tools/
./kolla-ansible -i ../../multinode reconfigure
```

As métricas com *Archive Policy* `high` serão criadas para as novas instâncias. As instâncias existentes permanecerão com a política `low`.


## 9. Adicionar um Nó de Computação

Os nomes das interfaces de rede devem ser iguais aos demais nós.

Host: **openstack-compute02**
- Interface **enp0s3**: 192.168.0.202/24 (*Management*)  
- Interface **enp0s8**: 192.168.254.202/24 (*Provider*)

Passos: 


- Seguir os procedimentos do **item 1**, comuns a todos os nós.

- Adicionar o host `openstack-compute02` no `/etc/hosts` de todos os nós.

- No controlador, exportar as chaves SSH (usuários *root* e *stack*) para o host `openstack-compute02`, conforme o **item 2.3**

- No controlador, adicionar o host `openstack-compute02` nos arquivos abaixo dentro da chave **[compute]**. **Itens 2.6 e 2.9** respectivamente.
    - `/etc/ansible/hosts`
    - `/root/multinode`

Por fim, no controlador, realizar o deploy do nó de computação com o usuário `root`.

Assim como no item **2.11**, foram utilizados os comandos para `development`. O parâmetro `--limit` executa o comando apenas para o host informado.
```bash
# For development:
cd /root/kolla-ansible/tools/
./kolla-ansible -i ../../multinode bootstrap-servers --limit openstack-compute02
./kolla-ansible -i ../../multinode prechecks --limit openstack-compute02
./kolla-ansible -i ../../multinode pull --limit openstack-compute02
./kolla-ansible -i ../../multinode deploy --limit openstack-compute02
```

:warning: Notas:
>- Ao adicionar um nó posteriormente, pode ser que este nó utilize imagens do Docker mais recentes do que as utilizadas no outros nós, pois ao executar o comando de `pull`, as imagens são novamente baixadas do Docker Hub. **Não é recomendado** executar versões diferentes nos nós.
>
>- O Kolla tem o recurso de registro local do Docker para fazer cache das imagens, como mostra a [documentação multinode (Deploy a registry)](https://docs.openstack.org/kolla-ansible/victoria/user/multinode.html).  
Porém, esse recurso **não foi utlizado**. Durante o `pull` as imagens foram baixadas novamente do Docker Hub.


## 10. Remover um Nó de Computação
> `TODO`


## 11. Atualizar as imagens docker da release instalada

Para atualizar as imagens docker dos módulos do OpenStack, seguir os segintes passos.

1. Parar os conteiners:
    ```bash
    # For development:
    cd /root/kolla-ansible/tools/
    ./kolla-ansible -i ../../multinode stop --yes-i-really-really-mean-it
    ```
1. Fazer o pull das imagens:
    ```bash
    ./kolla-ansible -i ../../multinode pull
    ```
1. Fazer o upgrade:
     ```bash
    ./kolla-ansible -i ../../multinode upgrade
    ``` 
1. Remover as imagens antigas:
     ```bash
    ./kolla-ansible -i ../../multinode prune-images --yes-i-really-really-mean-it
    ``` 


## 12. TLS
[Documentação TLS](https://docs.openstack.org/kolla-ansible/victoria/admin/tls.html)

:warning: Notas:
>- Esta configuração foi feita apenas em **caráter de TESTE**.
>
>- O Kolla-Ansible gerou o certificado self-signed com validade de 01 (um) ano apenas.
>
>- Configuração exclusiva para ambientes de desenvolvimento. Em produção não utilizar certificado self-signed.
>
>- Não foi realizado teste de acesso a API por HTTPS.

 
Para habilitar o TLS, configurar os parâmetros abaixo no arquivo `/etc/kolla/globals.yml`:

```bash
kolla_enable_tls_internal: "yes"
kolla_enable_tls_external: "{{ kolla_enable_tls_internal if kolla_same_external_internal_vip | bool else 'no' }}"
kolla_copy_ca_into_containers: "yes"

#If deploying on Debian or Ubuntu:
#openstack_cacert: "/etc/ssl/certs/ca-certificates.crt"

#If on CentOS or RHEL:
openstack_cacert: "/etc/pki/tls/certs/ca-bundle.crt"

kolla_enable_tls_backend: "yes"
# Não verifica o certificado self-signed
kolla_verify_tls_backend: "no"
```

Executar os seguintes comandos:
```bash
cd /root/kolla-ansible/tools/

# Gera o certificado self-signed
./kolla-ansible -i ../../multinode certificates

# Reconfigura o ambiente
./kolla-ansible -i ../../multinode reconfigure
```


## 13. Upgrade de versão
>`TODO`