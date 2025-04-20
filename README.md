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

- **Artifacts**: aqui são contidos os artefatos usados na validação dos dados;
- **Entities**: aqui é onde possuímos a entity principal do código (brewery) e valida se os dados estão de acordo com a natureza esperada (data types);
- **Use Cases**: aqui são contidos os casos de uso, nesse caso, os códigos com a lógica por trás da extração, transformação e escrita dos dados;
- **Handlers**: aqui está o código que irá nos permitir nos conectar com os fatores externos, sendo responsável por toda integração entre a AWS e as regras de negócio implementadas
nas entities e use cases;
- **Utils**: aqui teremos um código mais génerico, mas ainda sim útil, essa camada nos ajuda na geração dos logs;
- **Main**: esse código já pode ser considerado um dos fatores externos, ele irá permitir que iniciemos o software de modo apropriado, centralizando todo o código nele através de imports;
- **Unity & Integration Tests**: todo o código possui testes unitários e de integração, eles foram construídos com base no Pytest e podem ser visto na pasta "tests" na raiz do projeto.

Para uma compreensão mais aprofundada do código, recomendo que leia as docstrings, todas as funções, métodos, classes e módulos possuem docstrings no próprio código.

### Arquitetura da Pipeline de CI/CD

<p align="center">
  <img src="https://i.imgur.com/XY9rrdK.png" alt="Brewery ETL" width="1200">
</p>

Aqui temos a pipeline de CI/CD do projeto que roda no github actions, ela irá funcionar como mostrado acima, mas precisará de alguns secrets que estão descritas no passo a passo.

### Arquitetura da Cloud

<p align="center">
  <img src="https://i.imgur.com/jiiDzKI.png" alt="Brewery ETL" width="1200">
</p>

Aqui é a arquitura mais completa da cloud, no decorrer dessa documentação já foi explicado como ela funciona em partes, mas é possível visualizá-la toda conectada agora.

Existem alguns pontos de melhoria possíveis para esse projeto:

- **Implementação de Cloudwatch Alarms**: implementar o cloudwatch alarms para avisar quando ocorrer um erro relacionado a recursos computacionais na EC2 poderia cobrir erros que ainda não foram cobertos.
Isso não foi implementado, pois não há necessidade real visto que a quantidade de dados é baixa e fixa para cada run do ETL, porém, ainda poderia ser interessante implementar por questões de segurança.
- **Implementação de Auto Scaling Policy**: implementar uma auto scaling policy para que caso precise de mais poder processual também é algo válido, porém aqui também não há necessidade real visto
que os dados são poucos e a quantidade não é variável por run do ETL.

## Como implementar o projeto

Antes de tudo, gostaria de deixar um aviso aqui, sobre dois possíveis erros que podem ocorrer ao tentar implementar o projeto em uma conta nova da AWS:

1. **ECR Build Error**: quando o terraform for criar o ECR, pode haver um erro na pipeline, apenas rode novamente, se o erro persistir, aguarde a AWS liberar seu acesso ao EC2 para ativar novamente a pipeline;
2. **Lambda Create EC2 Error**: outro erro que irá ocorrer é a AWS bloquear sua lambda de criar uma EC2, recomendo novamente aguardar a AWS liberar seu acesso ao EC2 para poder ativar mais uma vez a lambda;
3. **Bucket Creation Error**: caso você esqueça de mudar o nome dos buckets irá ocorrer um erro, esse é um ponto de grande atenção, siga o tutorial e os substitua.

Abaixo temos o passo a passo de como implementar o projeto.

### Passo 1: Setup AWS Account

#### Criando conta na AWS

Para criar uma conta na AWS, eu recomendo seguir o passo a passo da documentação oficial: https://aws.amazon.com/resources/create-account/

#### Criando ADMIN IAM

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/VSyHOs0TgAI/hqdefault.jpg)](https://youtu.be/VSyHOs0TgAI)

É recomendado que crie a conta com permissão de ADMIN, pois existem vários serviços utilizados nesse projeto, caso não seja possível, recomendo ir estudando e dando as permissões específicas.

#### Criando S3 para terraform state

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/PSTP0EjSkDg/hqdefault.jpg)](https://youtu.be/PSTP0EjSkDg)

OBS: Não colocar o mesmo nome do S3 Bucket que eu indiquei aqui, pois os buckets devem ter nomes únicos globalmente.

### Passo 2: Setup Github Repository e Rodar os Actions

#### Clone o repositório original

Clone o repositório original na sua máquina local com o comando: git clone https://github.com/Valcilio/brewerie_data_lake2.git

#### Criando um repositório no Github e Configurando Secrets

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/e_mc9XcOoKk/hqdefault.jpg)](https://youtu.be/e_mc9XcOoKk)

As secrets a serem configuradas, são essas:

- **ACCOUNT_ID**: o ID da sua conta da AWS;
- **AWS_ACCESS_KEY_ID**: o ID do seu IAM User na AWS;
- **AWS_DEFAULT_REGION**: a região da AWS onde você irá deployar a aplicação;
- **AWS_SECRET_ACCESS_KEY**: a secret access key do seu IAM User na AWS;
- **SNS_EMAIL_SUBSCRIBED**: o email que irá receber notificações da AWS em caso de erro.

#### Substituindo os nomes dos buckets

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/DMzeRniHIcA/hqdefault.jpg)](https://youtu.be/DMzeRniHIcA)

Os nomes dos buckets que precisam ser substituídos são os seguintes:

1. brewery-bronze-layer2
2. brewery-silver-layer2
3. brewery-gold-layer2
4. brewery-athena-outputs2
5. brewery-test-files-temp2
6. terraform-states-brewery2

O 6º deve ser substítuido pelo nome do bucket que você criou manualmente, os demais podem ser nomes a gosto, recomendo substituir da forma indicada no vídeo para previnir erros.

#### Primeiro Commit: Ativando Github Actions

Adicione o repositório criado como a origin e mande o código clonado para ele.

#### Acompanhando o Deployment do Actions

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/BMx0tuVAqQo/hqdefault.jpg)](https://youtu.be/BMx0tuVAqQo)

### Passo 3: Testar o Projeto no Console da AWS

#### Triggering Lambda Function

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/a0LdPyWOHCE/hqdefault.jpg)](https://youtu.be/a0LdPyWOHCE)

#### Triggering Glue Crawler e Rodando Queries

Clique na imagem abaixo que ela irá lhe redirecionar a um vídeo demonstrando como fazê-lo:

[![Assista ao vídeo](https://img.youtube.com/vi/L8WCWy70ReY/hqdefault.jpg)](https://youtu.be/L8WCWy70ReY)
