# Gnocchi - Calcular rate a partir da Release Stein

Referências:  
[How I Learned to Stop Worrying and Love Gnocchi aggregation](https://berndbausch.medium.com/how-i-learned-to-stop-worrying-and-love-gnocchi-aggregation-c98dfa2e20fe)  
[OpenStack get vm cpu_util with Stein version](https://stackoverflow.com/questions/56216683/openstack-get-vm-cpu-util-with-stein-version)

## Ex: Calcular cpu_util em %
`<server-id>` é o resource id da instência no gnocchi.

### Mostra as coletas em NS (nanosegundos) Victoria release
```bash
# Default: MEAN
gnocchi measures show --resource-id <server-id> cpu
```

### Valor Médio, igual ao anterior
```bash
gnocchi measures show --resource-id  <server-id> cpu --aggregation mean
```

### Valor Máximo  
```bash
gnocchi measures show --resource-id  <server-id> cpu --aggregation max
```

### Valor Mínimo 
```bash
gnocchi measures show --resource-id  <server-id> cpu --aggregation min
```

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
