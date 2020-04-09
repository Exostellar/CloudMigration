#!/bin/bash

. config.sh

IPSUFFIX=1

set -ex

if [ ! -d "$TEMP" ]; then
    mkdir -p $TEMP
fi

touch tunnels.txt

if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
fi

yum install -y wget rpm-build openssl-devel gcc autoconf automake libtool python-twisted-core PyQt4 desktop-file-utils groff graphviz selinux-policy-devel libcap-ng-devel

mkdir -p $TEMP/rpmbuild/SOURCES
cd $TEMP/rpmbuild/SOURCES
wget https://www.openvswitch.org/releases/openvswitch-2.5.9.tar.gz
tar xzf openvswitch-2.5.9.tar.gz
rpmbuild --define "_topdir $TEMP/rpmbuild/" -bb --nocheck openvswitch-2.5.9/rhel/openvswitch-fedora.spec
cd ../RPMS/x86_64/
rpm -i openvswitch-2.5.9-1.el7.x86_64.rpm
systemctl start openvswitch.service
systemctl enable openvswitch.service


yum install -y nfs-utils
mkdir -p $NFS_ROOT
/bin/cp -f $BASE/controller/exports /etc/exports
sed -c -i "s:/root/nfsroot:$NFS_ROOT:" /etc/exports

#touch /etc/sysconfig/iptables
#service iptables restart
#chkconfig iptables on
#iptables -I INPUT -m state --state NEW -p udp --dport 4789 -s 0.0.0.0/0 -j ACCEPT
#service iptables save

ovs-vsctl add-br brvif1.4

ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up

cd $BASE
python build_bridges.py

echo "ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up" >> /etc/custom_init.sh


#iptables -I INPUT --in-interface brvif1.4 -j ACCEPT
#service iptables save

#service rpcbind restart
#service nfs restart
#chkconfig nfs on

#iptables --table nat -I POSTROUTING --out-interface eth0 -j MASQUERADE
#iptables -I FORWARD --in-interface brvif1.4 -j ACCEPT
#iptables -I FORWARD -o brvif1.4 -m state --state RELATED,ESTABLISHED -j ACCEPT
#echo 1 > /proc/sys/net/ipv4/ip_forward
#echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
#service iptables save


echo "ALL FINISHED." 
