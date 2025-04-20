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
  <img src="https://i.imgur.com/pf6Td8R.png" alt="Brewery ETL" width="800">
</p>

A extração, transformação e escrita (ETL) é realizada através de um processo que ocorre quando ativado por um eventbridge rule que irá ativar um lambda o qual criará uma EC2,
tal EC2 irá fazer pull de uma imagem docker do Amazon ECR para poder rodar o código python de modo conteinerizado. Tal processo irá nos levar ao seguinte:

- **Extração**: Irá ser extraído 200 registros do Open Brewery DB e depois salvo um parâmetro no Parameter Store o qual irá ajudar a indicar como extrair os próximos 200 registros
quando o ETL for rodar novamente;
- **Transformação**: foi usado esse mesmo ETL para transformar os dados com código Python.
    -  **Geração da coluna "brewery_location"**: ao concatenar as colunas "country", "state_province" e "city", tal transformação foi feita para ajudar a salvar os dados de 
    modo particionado pela localização dos brewery na silvar layer.
    - **Estruturação dos dados**: para que seja possível salvar e acessar os dados de modo mais eficiente, além de realizar queries que puxem-os, é interessante que salvemos os dados
    no formato parquet, o qual também é o formato ideal para salvar os dados na silver layer.
    - **Desenvolvimento de View**: por fim, para que seja possível ter acesso rápido a informações de quantidade de breweries por tipo e localidade, foi criado criado um outro arquivo parquet
    que já estava agregado pelas informações de localidade e tipo dos breweries. Essa view foi salva na Gold Layer para acesso futuro e rápido.
- **Escrita**: a escrita dos dados foi toda feita dentro de buckets do S3, sendo um bucket para cada uma das layers (bronze, silver e gold). Tal escrita foi feita encriptada com uma chave KMS
para garantir maior segurança dos dados no client side.

### Medallion Architecture com Amazon S3 (+ Lifecycle e AWS KMS)

<p align="center">
  <img src="https://i.imgur.com/NT9IPRQ.png" alt="Brewery ETL" width="800">
</p>

A arquitetura do medalhão aqui foi construída usando três buckets diferentes, cada um para uma camada: bronze, prata e ouro. Cada bucket possui sua própria lifecycle rule.

- **Bronze Layer**: mantém os dados no seu formato bruto, sua lifecycle manda os dados para o S3 Glacier após 30 dias para tornar mais barato;
- **Silver Layer**: mantém os dados estruturados, sua lifecycle manda os dados para o S3 Glacier após 90 dias para tornar mais barato;
- **Gold Layer**: mantém as views dos dados, não possui lifecycle, pois visa que os dados devem sempre estar disponíveis rapidamente.

### Monitoramento do ETL

<p align="center">
  <img src="https://i.imgur.com/fwOdDL1.png" alt="Brewery ETL" width="300">
</p>

O cloudwatch ajuda no monitoramento do ETL ao acompanhar os logs, tanto da lambda, quanto do EC2 e nos deixar a par do que ocorre no ETL em tempo real.

## Acesso aos Dados

<p align="center">
  <img src="https://i.imgur.com/sgNtwqO.png" alt="Brewery ETL" width="600">
</p>

Para permitir o acesso às views via SQL, foi implementado um crawler no Glue que cataloga os dados dentro da Gold Layer e os põe em uma database do Glue, assim
permitindo que o Athena consiga fazer queries nesses dados.

### Error Handling (Alertas e Retries)

<p align="center">
  <img src="https://i.imgur.com/s6fyoko.png" alt="Brewery ETL" width="600">
</p>

Em caso de erro, o ETL irá enviar uma mensagem via SNS para o e-mail dos usuários inscritos avisando do erro no ETL e também irá iniciar um retry que pode ocorrer até 3x consecutivas, até
dar erro e também ser enviada uma outra mensagem avisando que os retries não foram bem sucedidos para o e-mail dos usuários responsáveis pelo ETL.

## Arquitetura do Projeto

Nessa seção será explicado como foi estrurado a arquitetura do projeto como um todo e repartido em três partes: software, CI/CD e Cloud.

### Arquitetura do Software

<p align="center">
  <img src="https://i.imgur.com/Eyycvqd.png" alt="Brewery ETL" width="800">
</p>

Aqui foi decidido utilizar uma arquitetura de software conhecida como clean architecture. Cada camada irá possuir uma parte da aplicação com responsabilidades semelhantes, segue as camadas:

- **Artifacts**: aqui são contidos os artefatos usados na validação dos dados.
- **Entities**: aqui é onde possuímos a entity principal do código (brewery) e valida se os dados estão de acordo com a natureza esperada (data types).
- **Use Cases**: aqui são contidos os casos de uso, nesse caso, os códigos com a lógica por trás da extração, transformação e escrita dos dados.
- **Handlers**: aqui está o código que irá nos permitir nos conectar com os fatores externos, sendo responsável por toda integração entre a AWS e as regras de negócio implementadas
nas entities e use cases.
- **Utils**: aqui teremos um código mais génerico, mas ainda sim útil, essa camada nos ajuda na geração dos logs.
- **Main**: esse código já pode ser considerado um dos fatores externos, ele irá permitir que iniciemos o software de modo apropriado, centralizando todo o código nele através de imports.
- **Unity & Integration Tests**: todo o código possui testes unitários e de integração, eles foram construídos com base no Pytest e podem ser visto na pasta "tests" na raiz do projeto.

Para uma compreensão mais aprofundada do código, recomendo que leia as docstrings, todas as funções, métodos, classes e módulos possuem docstrings no próprio código.

### Arquitetura da Pipeline de CI/CD

<p align="center">
  <img src="https://i.imgur.com/XY9rrdK.png" alt="Brewery ETL" width="1200">
</p>

Aqui temos a pipeline de CI/CD do projeto que roda no github actions, ela irá funcionar como mostrado acima, mas precisará de alguns secrets que estão descritos
abaixo. Secrets:

- ****:

### Arquitetura da Cloud

<p align="center">
  <img src="https://i.imgur.com/jiiDzKI.png" alt="Brewery ETL" width="800">
</p>

- Trade-offs;
- Utilidade de cada serviço.

## Como implementar o projeto

- Possíveis erros e soluções rápidas.

### Passo 1: Setup AWS Account

#### Criando conta na AWS

#### Criando ADMIN IAM

#### Criando S3 para terraform state

### Passo 2: Setup Github Repository e Rodar os Actions

#### Criando um repositório no Github e clonando o original

#### Substituindo os nomes dos buckets

#### Setando Repository Secrets no Github

#### Primeiro Commit: Ativando Github Actions

#### Acompanhando o Deployment do Actions

### Passo 3: Testar o Projeto no Console da AWS

#### Triggering Lambda Function

#### Acompanhando EC2 Instance

#### Triggering Glue Crawler

#### Configurando o Athena e Rodando Queries
