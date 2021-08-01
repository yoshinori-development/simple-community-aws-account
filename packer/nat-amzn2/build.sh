#!/bin/sh

SCRIPT_NAME=`basename "$0"`
SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

export AWS_DEFAULT_REGION="ap-northeast-1"

packer build \
  -var-file=variable.pkrvars.hcl \
  packer.pkr.hcl