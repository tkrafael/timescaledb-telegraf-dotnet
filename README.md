# Timescaledb - Tutorial

## Criando uma aplicação .netcore e gerando sua primeira métrica

Utilizaremos a biblioteca App.Metrics para integração das métricas com o telegraf

Para o telegraf, vamos utilizar como inputs:
- cpu (para avaliar o consumo da máquina), gerado pelo próprio telegraf
- executions: gerado pela aplicação


Pacotes necessários:

```
dotnet add package App.Metrics.Formatters.InfluxDB
dotnet add package App.Metrics.AspNetCore.All
dotnet add package App.Metrics.Reporting.HTTP
```

Softwares necessários:

- dotnet sdk/dotnet runtime
- editor de textos (vscode recomendado)
- docker / docker-compose
- navegador web


1. Utilizaremos um worker que vai gerar métricas a cada segundo e gerando uma dimensão (filtro) representado pelo digito do segundo que ele foi executado (mod 2)
2. Para o banco, faremos a criação de de um hypertable nessa tabela e depois faremos o particionamento, retenção e compressão dos chunks

## Passo a passo:

1. Inicializar o docker/docker-compose com os containers necessários:

``` bash
docker-compose -f docker-compose-telegraf-grafana.yml up -d
```

2. Execução da aplicação dotnet
3. Criação das métricas no grafana
4. Bookkeeping do banco de dados e explicação de como ele funciona