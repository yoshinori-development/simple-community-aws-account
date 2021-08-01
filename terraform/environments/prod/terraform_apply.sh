#!/bin/sh

SCRIPT_NAME=`basename "$0"`
SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

export AWS_DEFAULT_REGION="ap-northeast-1"

terraform apply \
  -var-file=terraform.tfvars.json \
  -var-file=profile.tfvars.hcl