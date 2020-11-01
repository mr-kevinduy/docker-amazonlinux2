# Amazon Linux AMI 2

### docker-compose.yml

```sh
version: '3'

services:
  app:
    build: kevinduy/amazonlinnux2
    tty: true
    restart: always
    volumes:
      - ./app:/var/www/app
    ports:
      - "80:80"
      - "433:443"
    command: /bin/bash -c "/install/serve.sh *:80 lv.test /var/www/app/public && /usr/bin/env bash start;sleep infinity"
    links:
      - db
  db:
    image: mysql:5.7
    restart: always
    command: ["mysqld", "--character-set-server=utf8", "--collation-server=utf8_general_ci", "--skip-character-set-client-handshake"]
    volumes:
      - ./.docker/mysql:/var/lib/mysql
      - ./.docker/data:/var/data
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: laravel
      MYSQL_ROOT_PASSWORD: root
```

### Configs

```sh
#!/bin/bash

# Check OS
cat /etc/system-release

# Set timezone to Japan
# ls -a /usr/share/zoneinfo
sed -i -e "s/ZONE=\"UTC\"/ZONE=\"Japan\"/g" /etc/sysconfig/clock
ln -sf /usr/share/zoneinfo/Japan /etc/localtime

reboot
```

### Install basic packages:

```sh
#!/bin/bash

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
```

# Other install (have not in this Image)

### Cron and Incron

```sh
#!/bin/bash

# Update and install packages
yum update -y && yum install -y \
vixie-cron \
epel-release \
&& yum clean all

# Change yum config use el in sub config. Default: latest (el7).
sed -i "s|releasever=latest|#releasever=latest|g" /etc/yum.conf

# Install incrond
wget http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/incron-0.5.9-2.el6.rf.x86_64.rpm
yum localinstall incron*rpm
```

### Apache 2 (httpd)

```sh
#!/bin/bash

# Pre install
yum remove -y httpd
yum remove -y httpd-tools

# Update and install packages
yum update -y && yum install -y httpd24
service httpd start
```

### Add user and serve

```sh
# Add user
useradd -m deploy
usermod -aG wheel deploy
usermod -aG wheel apache

sed -i "s|# %wheel  ALL=(ALL) NOPASSWD: ALL|%wheel  ALL=(ALL) NOPASSWD: ALL|g" /etc/sudoers
sed -i "s|#Group apache|Group wheel|g" /etc/httpd/conf/httpd.conf

chown -R apache:wheel /var/www
chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;

# Setup serve
#sed -i "s|#ServerName www\.example\.com:80|ServerName $HOSTNAME:80|g" /etc/httpd/conf/httpd.conf

echo "NETWORKING=yes" > /etc/sysconfig/network

# ---------------- HTTPD ----------------
# cd /var/www
# git clone https://github.com/mr-kevinduy/lv-testing.git
# chown -R apache:wheel /var/www/lv-testing
# chmod 2775 /var/www/lv-testing
# find /var/www/lv-testing -type d -exec sudo chmod 2775 {} \;
# find /var/www/lv-testing -type f -exec sudo chmod 0664 {} \;
# vi /etc/httpd/conf.d/lv-testing.conf
: <<'END'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/lv-testing/public
    ErrorLog "/var/log/httpd/lv-testing-error.log"
    CustomLog "/var/log/httpd/lv-testing-access.log" common

    <Directory "/var/www/lv-testing/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
END

service httpd restart
```

OR

```sh
#!/bin/bash
# Usage:
# ./this_file.sh *:80 localhost /var/www/lv-testing/public

vthost="<VirtualHost $1>
    ServerName $2
    DocumentRoot $3
    ErrorLog "/var/log/httpd/$2-error.log"
    CustomLog "/var/log/httpd/$2-access.log" common

    <Directory $3>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
"
echo "$vthost" > "/etc/httpd/conf.d/$2.conf"
```

### PHP, Composer

```sh
#!/bin/bash

# Update and install packages
yum update -y && yum install -y \
php73 \
php73-pdo \
php73-mbstring \
php73-xml \
php73-json \
php73-bcmath \
php73-mysqlnd \
&& yum clean all

# Install composer
cd ~
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
ln -s /usr/local/bin/composer /usr/bin/composer
```

### Mysql

```sh
#!/bin/bash

# Update and install packages
yum update -y

# Install mysql
# yum remove -y mysql80-community-release.noarch
# yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el6-1.noarch.rpm

# yum-config-manager --disable mysql80-community
# yum-config-manager --enable mysql57-community
# yum info mysql-community-server
# mysql-community-common, mysql-community-client, mysql-community-libs
# yum install -y mysql-community-server

# service mysqld start
# systemctl start mysqld.service
# systemctl enable mysqld.service
```

```sh
# ---------------- MYSQL ----------------
# cat /var/log/mysqld.log | grep password
# #### Default: orEVcjjsj7&l - New pass: Kevin@123
# mysql_secure_installation
# #### No - y - y - y -y
# service mysqld stop
# chkconfig mysqld on
# service mysqld start
# mysql -u root -p
# show global variables like 'character%';
# show global variables like 'collation%';
# exit
# vi /etc/my.cnf
: <<'END'
[mysqld]
character-set-server = utf8
collation-server = utf8_general_ci

[client]
default-character-set=utf8
END
# service mysqld restart
# mysql -u root -p
# CREATE DATABASE lv_testing CHARACTER SET utf8 COLLATE utf8_general_ci;
# ### Create user local and remote
# CREATE USER 'deploy'@'localhost' IDENTIFIED BY 'Kevin@123';
# CREATE USER 'deploy'@'%' IDENTIFIED BY 'Kevin@123';
# ### Add to manager 'lv_testing' database
# GRANT ALL PRIVILEGES ON lv_testing.* TO 'deploy'@'localhost';
# GRANT ALL PRIVILEGES ON lv_testing.* TO 'deploy'@'%';
```

### Nodejs

```sh
#!/bin/bash

# Update and install packages
yum update -y

# Install nodejs and yarn
curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -
yum install -y nodejs
npm install yarn -g
```

### Nginx

```sh

```
