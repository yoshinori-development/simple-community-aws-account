#!/bin/sh

set -aue

SCRIPT_NAME=`basename "$0"`
SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

profile="sc-develop"

export AWS_DEFAULT_REGION=ap-northeast-1
bucket_name=ys-simple-community-tfstate
dynamodb_table=simple-community-tfstate-lock

aws s3api create-bucket  \
  --profile $profile \
  --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION \
  --bucket $bucket_name

aws s3api put-bucket-versioning \
  --profile $profile \
  --bucket $bucket_name \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --profile $profile \
  --bucket $bucket_name \
  --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

aws s3api put-public-access-block \
  --profile $profile \
  --bucket $bucket_name \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

aws dynamodb create-table \
  --profile $profile \
  --table-name=$dynamodb_table  \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
