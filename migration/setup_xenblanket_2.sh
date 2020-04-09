#!/bin/bash

set -ex
. config.sh

if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
fi

#Install openvswitch
yum install -y wget rpm-build openssl-devel gcc libtool PyQt4 desktop-file-utils graphviz selinux-policy-devel libcap-ng-devel groff python-zope-interface python-twisted-core

mkdir -p $TEMP/rpmbuild/SOURCES
cd $TEMP/rpmbuild/SOURCES
wget https://www.openvswitch.org/releases/openvswitch-2.5.9.tar.gz
tar xzf openvswitch-2.5.9.tar.gz
rpmbuild --define "_topdir $TEMP/rpmbuild/" -bb --nocheck openvswitch-2.5.9/rhel/openvswitch-fedora.spec
cd ../RPMS/x86_64/
rpm -i openvswitch-2.5.9-1.el7.x86_64.rpm

#Start and enable openvswitch service
systemctl start openvswitch.service
systemctl enable openvswitch.service

sed -c -i "s/vif-bridge/vif-openvswitch/" /etc/xen/xl.conf
sed -c -i "s/#vif\.default\.script/vif\.default\.script/" /etc/xen/xl.conf

systemctl stop firewalld
systemctl disable firewalld
yum install -y iptables-services
yum install nfs-utils -y

ovs-vsctl add-br brvif1.4
ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up

cd $BASE
python build_bridges.py

echo "ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up" >> /etc/custom_init.sh

systemctl start iptables
systemctl enable iptables
iptables --table nat -I POSTROUTING --out-interface eth0 -j MASQUERADE
iptables -I FORWARD --in-interface brvif1.4 -j ACCEPT
iptables -I FORWARD -o brvif1.4 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I INPUT -s 192.168.1.0/24 -j ACCEPT

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

service iptables save


echo "ALL FINISHED."
