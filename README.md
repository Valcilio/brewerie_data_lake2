
# Brewery Data Lake Project

## Introduction

This project was built to deploy an ETL along with a data lake structure on AWS that retrieves data from the public Open BreweryDB API (site: https://www.openbrewerydb.org/).

### What is Open Brewery DB

Open Brewery DB is a public API that provides information about breweries, including location, name, contact number, and brewery type.
These data can be retrieved via API requests following the documentation available on the website (https://www.openbrewerydb.org/documentation/). Below is the data catalog:

#### 📑 Data Catalog — Open Brewery DB

| Field            | Data Type                   | Description                                                               |
|:-----------------|:----------------------------|:--------------------------------------------------------------------------|
| `id`             | `string` (UUID)             | Unique identifier of the brewery.                                         |
| `name`           | `string`                    | Name of the brewery.                                                      |
| `brewery_type`   | `string`                    | Type of brewery (e.g., `micro`, `nano`, `regional`, `brewpub`, `planning`, etc.). |
| `address_1`      | `string` or `null`          | Main address of the brewery.                                              |
| `address_2`      | `string` or `null`          | Additional address (optional).                                            |
| `address_3`      | `string` or `null`          | Another additional address (optional).                                    |
| `city`           | `string`                    | City where the brewery is located.                                        |
| `state_province` | `string` or `null`          | State or province (depending on the country).                             |
| `postal_code`    | `string`                    | Postal code (ZIP code).                                                   |
| `country`        | `string`                    | Country where the brewery is located.                                     |
| `longitude`      | `number` (`float`) or `null`| Longitude of the geographic location.                                     |
| `latitude`       | `number` (`float`) or `null`| Latitude of the geographic location.                                      |
| `phone`          | `string` or `null`          | Phone number of the brewery (unformatted).                                |
| `website_url`    | `string` or `null`          | Official website URL of the brewery.                                      |
| `state`          | `string`                    | State (abbreviation or name, as recorded in the database).                |
| `street`         | `string` or `null`          | Full street address (may match `address_1` or be derived).                |

## Features

This project includes several features to enable data retrieval from the API, transformation, and proper storage, as well as monitoring and error handling.
These functionalities are described in the sections below.

### Extraction, Transformation, and Load (+ AWS Parameter Store and EventBridge)

<p align="center">
  <img src="https://i.imgur.com/pf6Td8R.png" alt="Brewery ETL" width="800">
</p>

The ETL process is triggered by an EventBridge rule that activates a Lambda function, which in turn creates an ephemeral EC2 instance.
This EC2 pulls a Docker image from Amazon ECR to run the Python code in a containerized environment. This process includes:

- **Extraction**: 200 records are extracted from Open Brewery DB and a parameter is saved to Parameter Store, which helps indicate the next 200 records to fetch in the subsequent ETL run;
- **Transformation**: the same ETL is used to transform the data using Python code.
    - **Creation of the "brewery_location" column**: by concatenating the "country", "state_province", and "city" columns. This helps partition the data by brewery location in the silver layer.
    - **Data Structuring**: to efficiently store and query data, it is saved in the Parquet format, which is ideal for the silver layer.
    - **View Development**: to quickly access the number of breweries by type and location, an aggregated Parquet file was created and saved in the Gold Layer.
- **Load**: data is written to S3 buckets (one for each layer: bronze, silver, and gold). The write process uses KMS encryption to ensure client-side security.

This ETL process starts extracting data from the page number descripted in the SSM parameter store and update the parameter with the same number +4 (each extraction takes data from 4 pages), so
the next extraction always start from when the last one stopped.

### Medallion Architecture with Amazon S3 (+ Lifecycle and AWS KMS)

<p align="center">
  <img src="https://i.imgur.com/NT9IPRQ.png" alt="Brewery ETL" width="800">
</p>

This medallion architecture uses three different S3 buckets: one for each layer — bronze, silver, and gold. Each bucket has its own lifecycle rule.

- **Bronze Layer**: stores raw data. Lifecycle moves data to S3 Glacier after 30 days for cost reduction;
- **Silver Layer**: stores structured data. Lifecycle moves data to S3 Glacier after 90 days for cost efficiency;
- **Gold Layer**: stores data views. No lifecycle, as data needs to be available quickly.

### ETL Monitoring

<p align="center">
  <img src="https://i.imgur.com/fwOdDL1.png" alt="Brewery ETL" width="300">
</p>

CloudWatch monitors the ETL by tracking logs from both Lambda and EC2, giving real-time visibility into the ETL process.

## Data Access

<p align="center">
  <img src="https://i.imgur.com/sgNtwqO.png" alt="Brewery ETL" width="600">
</p>

To enable SQL access to the views, a Glue Crawler catalogs the data in the Gold Layer and places it into a Glue Database, allowing Athena to query the data.

### Error Handling (Alerts and Retries)

<p align="center">
  <img src="https://i.imgur.com/s6fyoko.png" alt="Brewery ETL" width="600">
</p>

In case of an error, the ETL sends a message via SNS to subscribed user emails and retries up to 3 times. If all retries fail, another message is sent to inform responsible users.

## Project Architecture

This section explains the overall project architecture, divided into three parts: software, CI/CD, and cloud.

### Software Architecture

<p align="center">
  <img src="https://i.imgur.com/Eyycvqd.png" alt="Brewery ETL" width="800">
</p>

A clean architecture was adopted. Each layer has similar responsibilities:

- **Artifacts**: contains artifacts for data validation;
- **Entities**: contains the main entity (brewery), validating the expected data types;
- **Use Cases**: contains use cases, such as code for data extraction, transformation, and loading;
- **Handlers**: connects external factors (AWS integration) to business rules from entities and use cases;
- **Utils**: generic yet useful code, such as log generation;
- **Main**: entry point that centralizes imports to launch the software;
- **Unit & Integration Tests**: located in the `tests` folder, built with Pytest.

For deeper understanding, check the docstrings in each function, method, class, and module.

### CI/CD Pipeline Architecture

<p align="center">
  <img src="https://i.imgur.com/XY9rrdK.png" alt="Brewery ETL" width="1200">
</p>

The CI/CD pipeline runs on GitHub Actions. It functions as shown, but requires configuration of some secrets (explained below).

### Cloud Architecture

<p align="center">
  <img src="https://i.imgur.com/jiiDzKI.png" alt="Brewery ETL" width="1200">
</p>

This diagram shows the complete cloud architecture. Individual components were discussed earlier, and here they are shown fully connected.

Possible improvements:

- **Implement CloudWatch Alarms**: Could help detect EC2-related issues. Not implemented due to the low, fixed data volume, but could enhance reliability.
- **Implement Auto Scaling Policy**: Not necessary for this static data quantity, but could help if requirements grow.

Those two improvements points wasn't implemented because the quantity of data is static (always 200 jsons), so the chance to we need some alarms or auto scaling
to handle computer resources problems is very low, but we could put it just for security reasons depending of the context. One other point is:

- **Implement Custom Security Group, VPC and Subnet Config**: Could help to protect the EC2 from external invasions by limiting the IPs which can access the EC2.

This point wasn't implemented because the EC2 instances created aren't permanent, they only works during the process and after this they are terminated, so the chance
to they being invaded is very low. But we could implement those IP restrictions to the instance if we want more security.

## How to Deploy the Project

There is three common errors when deploying to be aware and avoid, the first two occur when you create a new aws account and
the EC2 access wasn't granted yet, last one is if you forget to rename the buckets:

1. **ECR Build Error**: If an error occurs, rerun the pipeline. If it persists, wait for AWS to grant EC2 access;
2. **Lambda EC2 Creation Error**: AWS might block Lambda from creating an EC2. Wait for EC2 access to be unlocked;
3. **Bucket Creation Error**: If you forget to rename buckets, this error will occur. Follow the tutorial carefully.

Below follow the tutorial.

### Step 1: AWS Account Setup

#### Create AWS Account

Follow AWS’s official guide: https://aws.amazon.com/resources/create-account/

#### Create ADMIN IAM

Click the image below to view the video tutorial (the user created in this video was deleted):

[![Watch Video](https://img.youtube.com/vi/VSyHOs0TgAI/hqdefault.jpg)](https://youtu.be/VSyHOs0TgAI)

It's recommended to create a user with admin access because of the high quantity of services needed by this project. If it's not possible just go giving the specific permissions.

#### Create S3 for Terraform State

Click the image below to view the video tutorial:

[![Watch Video](https://img.youtube.com/vi/PSTP0EjSkDg/hqdefault.jpg)](https://youtu.be/PSTP0EjSkDg)

OBS: create a S3 bucket with a different name from the one in this video.

### Step 2: Setup GitHub Repository and Run Actions

#### Clone Original Repository

```bash
git clone https://github.com/Valcilio/brewerie_data_lake2.git
```

#### Create New GitHub Repo and Set Secrets

[![Watch Video](https://img.youtube.com/vi/e_mc9XcOoKk/hqdefault.jpg)](https://youtu.be/e_mc9XcOoKk)

Secrets to configure:

- `ACCOUNT_ID`: AWS Account ID;
- `AWS_ACCESS_KEY_ID`: Key ID from your created admin iam user;
- `AWS_DEFAULT_REGION`: AWS default region to configure the resources;
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key from your created iam user;
- `SNS_EMAIL_SUBSCRIBED`: your e-mail which will receive the error messages.

#### Rename Buckets

Click in the image below:

[![Watch Video](https://img.youtube.com/vi/DMzeRniHIcA/hqdefault.jpg)](https://youtu.be/DMzeRniHIcA)

Buckets to rename:

1. brewery-bronze-layer2  
2. brewery-silver-layer2  
3. brewery-gold-layer2  
4. brewery-athena-outputs2  
5. brewery-test-files-temp2  
6. terraform-states-brewery2 (replace with your manually created bucket)

#### First Commit: Trigger GitHub Actions

Push your cloned code to the new GitHub repo.

#### Monitor Deployment

Click in the image below:

[![Watch Video](https://img.youtube.com/vi/BMx0tuVAqQo/hqdefault.jpg)](https://youtu.be/BMx0tuVAqQo)

### Step 3: Test the Project in AWS Console

#### Trigger Lambda Function

Click in the image below:

[![Watch Video](https://img.youtube.com/vi/a0LdPyWOHCE/hqdefault.jpg)](https://youtu.be/a0LdPyWOHCE)

You can take request example from the Eventbridge's rule it will be formatted, but you cant this below and format it by yourself too:

{
  "KMS_KEY" : "alias/brewery_etl_key",
  "START_PAGE_PARAMETER_NAME" : "brewery_start_page",
  "BRONZE_BUCKET" : "YOUR_BRONZE_BUCKET_NAME",
  "SILVER_BUCKET" : "YOUR_SILVER_BUCKET_NAME",
  "GOLD_BUCKET" : "YOUR_SILVER_BUCKET_NAME",
  "BRONZE_KEY" : "raw/jsons/data",
  "SILVER_KEY" : "processed/parquets/brewery_proc_data",
  "GOLD_KEY" : "brewery_type_loc_view",
  "AWS_REGION" : "us-east-1",
  "AWS_ACCOUNT_ID" : "YOUR_AWS_ACCOUNT_ID",
  "RETRY_NUMBER" : "0",
  "LAMBDA_NAME" : "brewery_etl_lambda"
}

Remember to replace the buckets' name and the aws account id with the one from your own account.

#### Trigger Glue Crawler and Run Queries

Click in the image below:

[![Watch Video](https://img.youtube.com/vi/L8WCWy70ReY/hqdefault.jpg)](https://youtu.be/L8WCWy70ReY)
