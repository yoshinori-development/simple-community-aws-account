#!/bin/sh

mkdir -p ./key_pairs
ssh-keygen -t rsa -b 4096 -f ./key_pairs/nat_instance -N ''
ssh-keygen -t rsa -b 4096 -f ./key_pairs/bastion -N ''
ssh-keygen -t rsa -b 4096 -f ./key_pairs/tool -N ''