#!/bin/bash

set -ex
. config.sh

#Install openvswitch
#yum install -y wget rpm-build openssl-devel gcc autoconf automake libtool python-twisted-core PyQt4 desktop-file-utils groff graphviz selinux-policy-devel libcap-ng-devel nfs-utils
yum install -y wget rpm-build openssl-devel gcc libtool PyQt4 desktop-file-utils graphviz selinux-policy-devel libcap-ng-devel groff python-zope-interface python-twisted-core

mkdir -p ~/rpmbuild/SOURCES
cd ~/rpmbuild/SOURCES
wget https://www.openvswitch.org/releases/openvswitch-2.5.9.tar.gz
tar xzf openvswitch-2.5.9.tar.gz
rpmbuild -bb --nocheck openvswitch-2.5.9/rhel/openvswitch-fedora.spec
cd ../RPMS/x86_64/
rpm -i openvswitch-2.5.9-1.el7.x86_64.rpm

#Start and enable openvswitch service
systemctl start openvswitch.service
systemctl enable openvswitch.service

ovs-vsctl add-br brvif1.4
ovs-vsctl add-br tunnel1.4

ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up
ifconfig tunnel1.4 up

echo "ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up" >> /root/custom_init.sh
echo "ifconfig tunnel1.4 up" >> /root/custom_init.sh

python build_bridges.py

#yes | cp $BASE/vif-openvswitch /etc/xen/scripts
#Uncomment vif default script
sed -c -i "s/vif-bridge/vif-openvswitch/" /etc/xen/xl.conf
sed -c -i "s/#vif\.default\.script/vif\.default\.script/" /etc/xen/xl.conf

yum install -y nfs-utils

echo "ALL FINISHED."
