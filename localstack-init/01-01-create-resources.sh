#!/usr/bin/env bash
set -e

echo "=== Creando buckets S3 ==="

awslocal s3 mb s3://la-huella-sentiment-reports
awslocal s3 mb s3://la-huella-uploads

echo "=== Aplicando política al bucket la-huella-uploads ==="

awslocal s3api put-bucket-policy \
  --bucket la-huella-uploads \
  --policy file://public-read-policy.json


echo "=== Creando tablas DynamoDB ==="

# --------------------------
# Tabla 1: la-huella-comments
# --------------------------
echo "Creando tabla: la-huella-comments"

awslocal dynamodb create-table \
  --table-name la-huella-comments \
  --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=productId,AttributeType=S \
      AttributeName=createdAt,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --global-secondary-indexes '[
      {
        "IndexName": "ProductIndex",
        "KeySchema": [
          { "AttributeName": "productId", "KeyType": "HASH" },
          { "AttributeName": "createdAt", "KeyType": "RANGE" }
        ],
        "Projection": { "ProjectionType": "ALL" },
        "ProvisionedThroughput": {
          "ReadCapacityUnits": 5,
          "WriteCapacityUnits": 5
        }
      }
    ]' \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


# --------------------------
# Tabla 2: la-huella-products
# --------------------------
echo "Creando tabla: la-huella-products"

awslocal dynamodb create-table \
  --table-name la-huella-products \
  --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=category,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --global-secondary-indexes '[
      {
        "IndexName": "CategoryIndex",
        "KeySchema": [
          { "AttributeName": "category", "KeyType": "HASH" }
        ],
        "Projection": { "ProjectionType": "ALL" },
        "ProvisionedThroughput": {
          "ReadCapacityUnits": 5,
          "WriteCapacityUnits": 5
        }
      }
    ]' \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


# --------------------------
# Tabla 3: la-huella-analytics
# --------------------------
echo "Creando tabla: la-huella-analytics"

awslocal dynamodb create-table \
  --table-name la-huella-analytics \
  --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=date,AttributeType=S \
  --key-schema \
      AttributeName=id,KeyType=HASH \
      AttributeName=date,KeyType=RANGE \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


echo "=== Creando colas SQS ==="

awslocal sqs create-queue --queue-name la-huella-processing-queue
awslocal sqs create-queue --queue-name la-huella-notifications-queue
awslocal sqs create-queue --queue-name la-huella-processing-dlq


echo "=== Creando grupos de logs de CloudWatch ==="

awslocal logs create-log-group --log-group-name /la-huella/sentiment-analysis
awslocal logs create-log-group --log-group-name /la-huella/api


echo "=== ✔ Recursos creados correctamente ==="