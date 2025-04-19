# Projeto Brewery Data Lake

## Introdução

Esse projeto foi construído poder realizar o deployment de um ETL junto de uma estrutura de um
datalake na AWS que pega os dados da API pública do Open BreweryDB (site: https://www.openbrewerydb.org/).

### O que é o Open Brewery DB

O Open Brewery DB é uma api pública que fornece informações sobre cervejarias, incluindo localidade, nome, número de contato e tipo da cervejaria.
Esses dados podem ser recuperados via requisição na API seguindo a documentação disponível no site (https://www.openbrewerydb.org/documentation/). Segue abaixo
o catalogo dos dados:

#### 📑 Catálogo de Dados — Open Brewery DB

| Campo            | Tipo de Dado                | Descrição                                                                 |
|:-----------------|:---------------------------|:--------------------------------------------------------------------------|
| `id`              | `string` (UUID)             | Identificador único da cervejaria.                                        |
| `name`            | `string`                    | Nome da cervejaria.                                                       |
| `brewery_type`    | `string`                    | Tipo de cervejaria (ex: `micro`, `nano`, `regional`, `brewpub`, `planning` etc). |
| `address_1`       | `string` ou `null`          | Endereço principal da cervejaria.                                         |
| `address_2`       | `string` ou `null`          | Endereço adicional (opcional).                                            |
| `address_3`       | `string` ou `null`          | Outro endereço adicional (opcional).                                      |
| `city`            | `string`                    | Cidade onde a cervejaria está localizada.                                 |
| `state_province`  | `string` ou `null`          | Estado ou província (dependendo do país).                                 |
| `postal_code`     | `string`                    | Código postal (CEP).                                                      |
| `country`         | `string`                    | País onde a cervejaria está localizada.                                   |
| `longitude`       | `number` (`float`) ou `null`| Longitude da localização geográfica.                                      |
| `latitude`        | `number` (`float`) ou `null`| Latitude da localização geográfica.                                       |
| `phone`           | `string` ou `null`          | Número de telefone da cervejaria (sem formatação).                        |
| `website_url`     | `string` ou `null`          | URL do site oficial da cervejaria.                                        |
| `state`           | `string`                    | Estado (abreviação ou nome, conforme o registro no banco).                |
| `street`          | `string` ou `null`          | Endereço completo da rua (pode coincidir com `address_1` ou ser derivado).|

## Funcionalidades

Esse projeto trouxe consigo várias funcionalidades para que seja possível obter os dados da API, transformá-los e salvá-los de modo adequado, além tornar possível monitorar e lidar com possíveis erros,
nos sub-tópicos abaixo temos essas funcionalidades mais explicadas.

### Extração, Transformação e Escrita (+ AWS Parameter Store e Eventbridge)

<p align="center">
  <img src="https://i.imgur.com/nsRcEKW.png" alt="Brewery ETL" width="600">
</p>



### Medallion Architecture com Amazon S3 (+ Lifecycle e AWS KMS)

### Monitoramento do ETL

### Error Handling (Alertas e Retries)

## Arquitetura do Projeto

- Limitações;
- Possíveis erros e soluções rápidas.

### Arquitetura do Software

- Desenho da Arquitetura;
- Trade-offs;
- Escolhas.

### Arquitetura da Pipeline de CI/CD

- Desenho da Arquitetura;
- Etapas;
- Jobs;
- Ferramentas.

### Arquitetura da Cloud

- Desenho da Arquitetura;
- Trade-offs;
- Utilidade de cada serviço.

## Como implementar o projeto

### Passo 1: Setup AWS Account

#### Criando conta na AWS

#### Criando ADMIN IAM

#### Criando S3 para terraform state

### Passo 2: Setup Github Repository

#### Criando um repositório no Github e clonando o original

#### Substituindo nome dos buckets

#### Setando Repository Secrets no Github

### Passo 3: Implementar o Projeto com o Github Actions

#### Primeiro Commit: Ativando Github Actions

#### Acompanhando o Deployment do Actions

### Passo 4: Testar o Projeto no Console da AWS

#### Triggering Lambda Function

#### Acompanhando EC2 Instance

#### Triggering Glue Crawler

#### Configurando o Athena e Rodando Queries
