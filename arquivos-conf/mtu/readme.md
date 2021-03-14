### Configuração do neutron para mudar o MTU das redes VXLAN.

As redes VXLAN tem o MTU padrão de 1450.  
1450 + 50bytes VXLAN header = 1500.  
Para evitar fragmentação o MTU foi alterado para 1550.  
Se precisar de VLAN no pacote original (dentro da VXLAN), aumentar o MTU para 1554.

⚠️ Para funcionar a rede física, no caso a `Management`, precisa ter MTU>=1550. A interface de rede em todos os nós precisa estar configurada com MTU>=1550.

#### Arquivos
- `/etc/kolla/config/neutron.conf`  
Este aquivo altera o MTU padrão para 1550.  
```bash
# File neutron.conf
[DEFAULT]
global_physnet_mtu = 1550
```

- `/etc/kolla/config/neutron/ml2_conf.ini`  
Este arquivo altera o path_mtu (tamanho máximo do pacote IP) para 1550, mas mantém o MTU da rede provider e 1500.  

``` bash
# File ml2_conf.ini

# path_mtu : Maximum size of an IP packet (MTU) that can traverse the underlying physical network infrastructure without fragmentation when using an overlay/tunnel protocol.
#            This option allows specifying a physical network MTU value that differs from the default global_physnet_mtu value.
#
# physical_network_mtus : A list of mappings of physical networks to MTU values. The format of the mapping is <physnet>:<mtu val>.
#                         This mapping allows specifying a physical network MTU value that differs from the default global_physnet_mtu value.

[ml2]
path_mtu = 1550
physical_network_mtus = physnet1:1500
```
