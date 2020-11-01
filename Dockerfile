FROM amazonlinux:2

MAINTAINER KevinDuy <mr.kevinduy@gmail.com>

# Install packages
COPY ./install.sh /install/install.sh
COPY ./serve.sh /install/serve.sh

RUN chmod +x /install/*.sh

RUN /bin/bash /install/install.sh

ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
  systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" ]

RUN yum -y install epel-release; yum -y install openssh-server; yum -y install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.7.0-1.el7.ans.noarch.rpm; yum -y install git; yum -y install coreutils; yum -y install shadow-utils; yum -y install vim; yum clean all; systemctl enable sshd.service; echo "root:password" | chpasswd 

WORKDIR /var/www/app

EXPOSE 22 80 443 9000
