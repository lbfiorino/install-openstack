# Gnocchi - Calcular rate a partir da Release Stein

**Ex: Calcular cpu_util em %**  
`<server-id>` é o resource id da instancia no gnocchi

## Mostra as medidas em NS (nanosegundos) Victoria release
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

### Mostra as medidas
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
:warning: ATENÇÃO COM A GRANULARIDADE:
>&ensp; 1.0    : Dividir por  1000000000.0  
>&ensp; 60.0   : Dividir por 60000000000.0  
>3600.0 : Dividir por 3600000000000.0  
```bash
gnocchi aggregates '(* (/ (aggregate rate:mean (metric cpu mean)) 1000000000.0) 100)' id=<server-id>
```
