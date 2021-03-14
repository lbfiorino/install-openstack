### Configuração do neutron para mudar o MTU das redes VXLAN.

As redes VXLAN tem o MTU padrão de 1450.  
1450 + 50bytes VXLAN header = 1500.  
Para evitar fragmentação o MTU foi alterado para 1550.  

#### Arquivos
- `/etc/kolla/config/neutron.conf`  
Este aquivo altera o MTU padrão para 1550.  
```bash
# File neutron.conf
[DEFAULT]
global_physnet_mtu = 1550
```

- `/etc/kolla/config/neutron/ml2_conf.ini`  
Este arquivo altera o path_mtu para 1550, mas mantém o MTU da rede provider e 1500.  
``` bash
# File ml2_conf.ini
[ml2]
path_mtu = 1550
physical_network_mtus = physnet1:1500
```
