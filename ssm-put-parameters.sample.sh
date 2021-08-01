#!/bin/sh

PROFILE="my-promotion-prod"
REGION="ap-northeast-1"

aws ssm put-parameter --profile $PROFILE --type SecureString --name promotion.prod.database_password --value dummy
aws ssm put-parameter --profile $PROFILE --type SecureString --name promotion.prod.x_cf_secret --value dummy
