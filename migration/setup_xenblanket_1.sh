#!/bin/bash

set -ex

. config.sh

yum install -y wget vim screen

if [ ! -d "$TEMP" ]; then
    mkdir -p $TEMP
fi

yum update -y
yum install -y epel-release
yum install -y git wget patch gcc bison flex elfutils-libelf-devel openssl-devel bc
cd $TEMP
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.15.5.tar.xz
tar xf linux-4.15.5.tar.xz
cd linux-4.15.5
if [ "$platform" = xen ]; then
        git clone https://github.com/Exotanium/Xen-Blanket-NG.git
        patch -p1 < Xen-Blanket-NG/linux-4.15.5.patch
fi
cp $BASE/kernel_config .config
make oldconfig
make xenconfig
make -j8 all
make modules_install
make install
cp .config /boot/config-4.15.5-xennested

yum groupinstall -y "Development Tools"
yum install -y dev86 xz-devel python-devel acpica-tools uuid-devel ncurses-devel glib2-devel pixman-devel yajl-devel zlib-devel systemd-devel libnl3-devel glibc-devel.i686 patch libuuid-devel
cd $TEMP
wget https://downloads.xenproject.org/release/xen/4.13.0/xen-4.13.0.tar.gz
tar xf xen-4.13.0.tar.gz
cd xen-4.13.0
if [ "$platform" = xen ]; then
        patch -p1 < $TEMP/linux-4.15.5/Xen-Blanket-NG/xen-4.13.0.patch
fi
./configure --disable-docs --disable-stubdom --enable-systemd
make -j8 dist-xen dist-tools
make install-tools install-xen

echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

sed -i 's/GRUB_DEFAULT.*/GRUB_DEFAULT\=\"CentOS Linux\, with Xen hypervisor\"/' /etc/default/grub
echo 'GRUB_CMDLINE_XEN_DEFAULT="dom0_max_vcpus=4 dom0_mem=4096M,max:4096M dom0_vcpus_pin=true"' >> /etc/default/grub
echo 'GRUB_CMDLINE_LINUX_XEN_REPLACE_DEFAULT="console=hvc0 earlyprintk=xen nomodeset"' >>/etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

systemctl enable xencommons
systemctl enable xen-qemu-dom0-disk-backend.service
systemctl enable xen-init-dom0.service
systemctl enable xenconsoled.service

echo "All completed. Check grub before reboot!"
