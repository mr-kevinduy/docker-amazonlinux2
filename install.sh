#!/bin/bash

# Set timezone to Japan
sed -i -e "s/ZONE=\"UTC\"/ZONE=\"Japan\"/g" /etc/sysconfig/clock
ln -sf /usr/share/zoneinfo/Japan /etc/localtime

# Update and install packages
yum update -y && yum install -y \
sudo \
git \
wget \
nano \
vim \
telnet \
htop \
&& yum clean all

yum install -y /usr/bin/systemctl
