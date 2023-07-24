# Etração, Transformação e Carga dos dados da rede RBB
Este projeto demonstra como extrair dados da blockchain RBB e carregá-lo em uma base de dados transacional. Isso permitirá observações variadas sobre a blockchain da RBB usando consultas SQL ou outras ferramentas analíticas, sendo um recurso valioso para atendimento do seu requisito de **transparência**.

O projeto usa o framework de código aberto [ethereum-etl](https://github.com/blockchain-etl/ethereum-etl). Este framework é usado para disponibilizar publicamente os dados da rede Ethereum no [Google BigQuery](https://goo.gl/oY5BCQ). Os esquemas de dados são aqueles providos pelo projeto [ethereum-etl-postgres](https://github.com/blockchain-etl/ethereum-etl-postgres).

    ----------   
    -        -     HTTP-RPC
    - Nó RBB -   ------------>
    -        -    (streaming)
    ---------- 

**OBS:** É  possível executar o *streaming* de dados usando o protocolo IPC para melhor desempenho, porém este método não foi testado neste projeto.

### Prerequisitos
- Docker 20.10.0+
- Docker Compose
- Habilitar no nó provedor dos dados o acesso [rpc-http](https://besu.hyperledger.org/stable/public-networks/how-to/use-besu-api/json-rpc#http). Parâmetros que devem estar configurados: *rpc-http-enabled, rpc-http-host, rpc-http-port, rpc-http-api, rpc-http-cors-origins, host-allowlist*. Para maiores detalhes, consulte a [documentação do Besu](https://besu.hyperledger.org/stable/public-networks/reference/cli/options).

## Executando o projeto

### Criando os esquemas de dados no Postgres
1. Inicie o *container* do Postgres. 
```
$ docker-compose up -d postgres
```

Confira se o *container* está em execução e verifique o seu log.
```
$ docker ps
$ docker logs postgres
```

2. Se o serviço do Postgres executar com sucesso, prossiga com a criação das tabelas e índices:
**OBS:** Os comandos a seguir serão executados em um terminal do *host*, mas poderiam ser executados diretamente em um terminal do *container* do Postgres, através da aplicação *psql*.
```
$ docker exec -it postgres sh -c "cat /data/sql/schema/*.sql | psql -U rbbusr -d rbb -h 127.0.0.1  --port 5432 -a"
$ docker exec -it postgres sh -c "cat /data/sql/indexes/*.sql | psql -U rbbusr -d rbb -h 127.0.0.1  --port 5432 -a"
```

Verifique se as tabelas foram criadas com sucesso:
```
$ docker exec -it postgres sh -c "echo '\dt' | psql -U rbbusr -d rbb -h 127.0.0.1  --port 5432 -a"
```
Exemplo de resultado:
```
\dt
             List of relations
 Schema |      Name       | Type  | Owner  
--------+-----------------+-------+--------
 public | accounts        | table | rbbusr
 public | blocks          | table | rbbusr
 public | contracts       | table | rbbusr
 public | logs            | table | rbbusr
 public | token_transfers | table | rbbusr
 public | tokens          | table | rbbusr
 public | traces          | table | rbbusr
 public | transactions    | table | rbbusr
(8 rows)
```

Verifique se os índices foram criados com sucesso:
```
$ docker exec -it postgres sh -c "echo \"
SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    indexname;
\" | psql -U rbbusr -d rbb -h 127.0.0.1  --port 5432 -a"
```

### Exportando os dados da blockchain para o Postgres
Os dados serão exportados através da aplicação **ethereum-etl**. Será usado o subcomando *stream* com carga diretamente no Postgres. Esse comando irá executar uma extração e carga na forma de *streaming*, ou seja, os dados serão continuamente extraídos da rede blockchain e carregados na base de dados do Postgres. 

O ethereum-etl usa o arquivo *last_synced_block.txt* no subdiretório *sync* para armazenar o estado do último bloco extraído e carregado no Postgres. Dessa forma, caso o serviço ou container do ethereum-etl pare, ele poderá ser reiniciado sem perda de dados.

Para maiores detalhes do processo, verifique o comando no arquivo ***docker-compose.yml*** e na [documentação do ethereum-etl](https://github.com/blockchain-etl/ethereum-etl/blob/develop/docs/commands.md#stream).

Para iniciar a extração e carga, ajuste no arquivo docker-compose.yml o parâmetro de identificação do nó provedor dos dados e execute:
```
$ docker-compose up -d ethereum-etl
```

Verifique se o container está em execução e se a extração e carga está ocorrendo:
```
$ docker ps
$ docker logs -f ethereum-etl
```

### Verificando o consumo de *gas* por organização
Para obter o consumo de *gas* por organização autorizada a enviar transações para a rede, é necessário alimentar manualmente a tabela ***accounts*** com as contas permissionadas e com as organizações a que pertencem. Esses dados podem ser obtidos no DApp de permissionamento e na Governança da RBB, que detém a relação de contas permissionadoras e as respectivas organizações parceiras.

Execute a consulta a seguir, cujo arquivo SQL poderá ser modificado com os critérios de restrição desejados.
```
$ docker exec -it postgres sh -c "cat /data/sql/queries/gas_usage_by_organization.sql | psql -U rbbusr -d rbb -h 127.0.0.1  --port 5432 -a"
```

Exemplo de retorno:
```
 organization |                from_address                | total_gas_used | transactions_count | min_block_number | max_block_number |    min_timestamp    |    max_timestamp    
--------------+--------------------------------------------+----------------+--------------------+------------------+------------------+---------------------+---------------------
 PRODEMGE     | 0x627306090abab3a6e1400e9345bc60c78a8bef57 |        9652791 |                 20 |               12 |              196 | 2023-04-14 16:39:55 | 2023-04-14 16:48:02
(1 row)
```

### pgAdmin
O projeto também inclui um container com o pgAdmin que pode, opcionalmente, ser executado para acesso à base de dados do Postgres através dessa ferramenta.

Para iniciar o pgAdmin, execute:
```
$ docker-compose up -d pgadmin
```

Acesse a interface do pgAdmin na máquina *host* em http://localhost:5080

### Limitações
Consulte <https://ethereum-etl.readthedocs.io/en/latest/limitations/>.