#!/bin/bash

sudo yum update -y

# timezone
sudo timedatectl set-timezone Asia/Tokyo

# locale
sudo localectl set-locale LANG=ja_JP.UTF-8

# set swap
sudo dd if=/dev/zero of=/swapfile bs=2M count=1024
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo sudo sed -i -e '$ a /swapfile swap swap defaults 0 0' /etc/fstab

# tools
## utility
sudo yum install -y git

## terraform
TERRAFORM_VERSION=1.0.1
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_arm64.zip
rm terraform_${TERRAFORM_VERSION}_linux_arm64.zip
sudo mv ./terraform /usr/local/bin

## packer
PACKER_VERSION=1.7.3
wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_arm64.zip
unzip packer_${PACKER_VERSION}_linux_arm64.zip
rm packer_${PACKER_VERSION}_linux_arm64.zip
sudo mv ./packer /usr/local/bin

# sudo yum install -y yum-utils
# sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
# sudo yum -y install packer
