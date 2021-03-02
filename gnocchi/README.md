# Gnocchi - Calcular métricas _cpu_util_ e _*.rate_ a partir da Release Stein
Algumas métricas foram descontinuadas a partir da release Stein. Com isso é preciso utilizar as funções do Gnocchi para calcular essas métricas.

### [Lista de métricas descontinuadas - Release Stein](https://docs.openstack.org/releasenotes/ceilometer/stein.html#relnotes-12-0-0-stable-stein-upgrade-notes):
- The deprecated disk.* meters have been removed. Use the disk.device.* meters instead.
- **The deprecated meter for compute where removed:**
  - disk.read.requests.rate
  - disk.write.requests.rate
  - disk.read.bytes.rate
  - disk.write.bytes.rate
  - disk.device.read.requests.rate
  - disk.device.write.requests.rate
  - disk.device.read.bytes.rate
  - disk.device.write.bytes.rate

### [Deprecation Notes - Release Rocky](https://docs.openstack.org/releasenotes/ceilometer/rocky.html#deprecation-notes):
- _cpu_util and *.rate meters are deprecated and will be removed in future release in favor of the Gnocchi rate calculation equivalent._

## Referências
1. [How I Learned to Stop Worrying and Love Gnocchi aggregation](https://berndbausch.medium.com/how-i-learned-to-stop-worrying-and-love-gnocchi-aggregation-c98dfa2e20fe)  
2. [OpenStack get vm cpu_util with Stein version](https://stackoverflow.com/questions/56216683/openstack-get-vm-cpu-util-with-stein-version)

## Ex: Calcular cpu_util em %
`<server-id>` é o resource id da instância no gnocchi.

### Mostra as coletas em NS (nanosegundos) Victoria release
```bash
# Default: MEAN
gnocchi measures show --resource-id <server-id> cpu

# OR 
gnocchi measures show --resource-id  <server-id> cpu --aggregation mean
```

### Usando a função de agregação rate:mean
Para os comandos abaixo é preciso que a Archive Policy tenha o método de agregação `rate:mean`.  
Útil para Achive Police `ceilometer-high-rate` e `ceilometer-low-rate`.
```bash
gnocchi measures show --resource-id <uuid> --aggregation rate:mean cpu

# Or use the dynamic aggregation feature for the same result:
gnocchi aggregates '(metric cpu rate:mean)' id=<uuid>
```
Caso a Archive Policy não tenha o método de agregação `rate:mean`, utilizar o comando `gnocchi aggregates` a seguir.

## Usando gnocchi aggregates

### Mostra as coletas
```bash
# Igual a : gnocchi measures show --resource-id <server-id> cpu
gnocchi aggregates '(metric cpu mean)' id=<server-id>
```

### Calcular a taxa (rate) em nanosegundos
```bash
gnocchi aggregates '(aggregate rate:mean (metric cpu mean))' id=<server-id>
```

### Converter a taxa para segundos (1s = 1000000000 nanosegundos)
```bash
gnocchi aggregates '(/ (aggregate rate:mean (metric cpu mean)) 1000000000.0)' id=<server-id>
```

### Converter para percentual
:warning: **Atenção com a Granularidade**:
| Granularidade | Dividir por |
| --- | --- |
| 1.0 | 1000000000.0 |
| 60.0 |  60000000000.0 |
| 3600.0 | 3600000000000.0 |

```bash
# Para granularidade 60.0
gnocchi aggregates '(* (/ (aggregate rate:mean (metric cpu mean)) 60000000000.0) 100)' id=<server-id>
```
