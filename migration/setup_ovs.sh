#!/bin/bash

set -ex
. config.sh

if [ ! -d "$TEMP" ]; then
    mkdir -p $TEMP
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

#Enable OVS support in Xen
sed -c -i "s/vif-bridge/vif-openvswitch/" /etc/xen/xl.conf
sed -c -i "s/#vif\.default\.script/vif\.default\.script/" /etc/xen/xl.conf
/usr/bin/cp -f $BASE/vif-openvswitch /etc/xen/scripts/

#Install customized init script
/usr/bin/cp -f $BASE/custom_init.service /etc/systemd/system
systemctl daemon-reload
systemctl enable custom_init.service
echo "#!/bin/bash" > /etc/custom_init.sh
chmod a+x /etc/custom_init.sh

#Create bridges
ovs-vsctl add-br brvif1.4
ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up

cd $BASE
python build_bridges.py
echo "ifconfig brvif1.4 192.168.1.$IPSUFFIX netmask 255.255.255.0 mtu $guest_mtu up" >> /etc/custom_init.sh

#NAT server for guest VMs
systemctl stop firewalld || true
systemctl disable firewalld || true
yum install -y iptables-services
systemctl start iptables
systemctl enable iptables

main_dev=`ip route show | grep 'default' | awk '{print $5}'`
iptables --table nat -I POSTROUTING --out-interface $main_dev -j MASQUERADE
iptables -I FORWARD --in-interface brvif1.4 -j ACCEPT
iptables -I FORWARD -o brvif1.4 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I INPUT -s 192.168.1.0/24 -j ACCEPT
iptables -I INPUT -p udp --dport 655 -j ACCEPT

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

service iptables save

#Install NFS support 
yum install nfs-utils -y

echo "ALL FINISHED."
