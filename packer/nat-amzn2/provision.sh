#!/bin/bash

sleep 30

sudo yum update -y

# timezone
sudo timedatectl set-timezone Asia/Tokyo

# locale
sudo localectl set-locale LANG=ja_JP.UTF-8

# IPフォワーディングを有効化
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo sh -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"

# iptables
sudo yum -y install iptables-services

## 設定を削除
sudo iptables -F

## NAT & IPマスカレード設定
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo service iptables save

sudo systemctl start iptables
sudo systemctl enable iptables