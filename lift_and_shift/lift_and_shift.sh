#!/bin/sh
set -ex
yum install -y jq qemu-img
#To use this script, target vm must be powered on.
#variables to be specified
OUTPUT_DIR=/path/to/output
VM_NAME=targetVmName
VM_IP=targetVmIP
ESX_HOST=ESXiIP
VCENTER_HOST=YourVcenterHostIP
VCENTER_USERNAME=YourVcenterUsername
VCENTER_PASSWORD=YourVcenterPassword
#you must escape special character by using % followed by its ASCII hex value
VCENTER_PASSWORD_ASCII=EscapedPassword
AUTH_HEADER=$(echo -n $VCENTER_USERNAME:$VCENTER_PASSWORD | base64)
KERNEL_VERSION=$(ssh root@${VM_IP} "grep -o 'vmlinuz\\S*' /proc/cmdline | sed s/vmlinuz-//")
EXTRA=$(ssh root@${VM_IP} cat /proc/cmdline)
SESSION_ID=$(curl "https://${VCENTER_HOST}/rest/com/vmware/cis/session" -X POST -H "Authorization: Basic ${AUTH_HEADER}" | jq -r ".value")
VM_VCENTER_ID=$(curl -X GET --header "Accept: application/json" --header "vmware-api-session-id: ${SESSION_ID}" "https://${VCENTER_HOST}/rest/vcenter/vm?filter.names=${VM_NAME}" | jq -r ".value[].vm")
NCPU=$(curl -X GET --header "Accept: application/json" --header "vmware-api-session-id: ${SESSION_ID}" "https://${VCENTER_HOST}/rest/vcenter/vm?filter.names=${VM_NAME}" | jq -r ".value[].cpu_count")
MEM_SIZE=$(curl -X GET --header "Accept: application/json" --header "vmware-api-session-id: ${SESSION_ID}" "https://${VCENTER_HOST}/rest/vcenter/vm?filter.names=${VM_NAME}" | jq -r ".value[].memory_size_MiB")
MAC_ADDR=$(curl -k -X GET --header "Accept: application/json" --header "vmware-api-session-id: ${SESSION_ID}" "https://${VCENTER_HOST}/rest/vcenter/vm/${VM_VCENTER_ID}" | jq -r ".value.nics[].value.mac_address")

#keep original mac and ip address
for device in $(ssh root@${VM_IP} ls -1 /sys/class/net); do
    if [ `ssh root@${VM_IP} ip address show dev $device | grep ${MAC_ADDR} -c` -ne $((0)) ]; then
        NIC_NAME=$device
    fi
done

ssh root@${VM_IP} mkdir -p /etc/udev/rules.d
ssh root@${VM_IP} touch /etc/udev/rules.d/70-persistent-net.rules
SPEC='SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"'${MAC_ADDR}'\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", NAME=\"'${NIC_NAME}'\"'
ssh root@${VM_IP} 'echo "'${SPEC}'" > /etc/udev/rules.d/70-persistent-net.rules'

#generate ramdisk inside vm
mkdir -p ${OUTPUT_DIR}
OS_RELEASE=$(ssh root@${VM_IP} cat /etc/os-release)
if echo $OS_RELEASE | grep -i -c centos; then
	ssh root@${VM_IP} mkinitrd --with xen_netfront --with xen_blkfront /tmp/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
elif echo $OS_RELEASE | grep -i -c ubuntu; then
	ssh root@${VM_IP} mkinitramfs -o /tmp/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
elif echo $OS_RELEASE | grep -i -c alpine; then
	ssh root@${VM_IP} mkinitfs -o /tmp/initramfs-${KERNEL_VERSION}.img 
else
	echo "Can not generate ramdisk inside vm"
	exit -1
fi

scp root@${VM_IP}:/tmp/initramfs-${KERNEL_VERSION}.img ${OUTPUT_DIR}
scp root@${VM_IP}:/boot/vmlinuz-${KERNEL_VERSION} ${OUTPUT_DIR}

#get vm datastore info in vCenter Server
DATACENTER=$(vifs --server ${VCENTER_HOST} --username ${VCENTER_USERNAME} --password ${VCENTER_PASSWORD} -C)
#export vm from vSphere
ovftool --powerOffSource vi://${VCENTER_USERNAME}:${VCENTER_PASSWORD_ASCII}@${VCENTER_HOST}/${DATACENTER}/vm/Discovered\ virtual\ machine/${VM_NAME} ${OUTPUT_DIR}
cd ${OUTPUT_DIR}/${VM_NAME}
for i in `ls *[0-9].vmdk`; do qemu-img convert -f vmdk $i -O raw ${OUTPUT_DIR}/${i/vmdk/raw} ; done
#qemu-img convert ${OUTPUT_DIR}/${VM_NAME}/${VM_NAME}.flat -O raw ${OUTPUT_DIR}/${VM_NAME}.raw


#create xen cfg file
touch ${OUTPUT_DIR}/${VM_NAME}.cfg
echo 'kernel = "'${OUTPUT_DIR}'/vmlinuz-'${KERNEL_VERSION}'"' >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo 'ramdisk = "'${OUTPUT_DIR}'/initramfs-'${KERNEL_VERSION}'.img"' >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo 'extra = "'${EXTRA}'"' >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo 'name = "'${VM_NAME}'"' >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo "memory = 4096" >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo "vcpu = 4" >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo "vif = ['mac=${MAC_ADDR},bridge=brvif1.4']" >> ${OUTPUT_DIR}/${VM_NAME}.cfg
echo "disk = [" >> ${OUTPUT_DIR}/${VM_NAME}.cfg
cd ${OUTPUT_DIR}
for i in `ls *[0-9].raw`;
do echo "'format=raw, vdev=xvda, access=w, target=${OUTPUT_DIR}/${i}'," >> ${OUTPUT_DIR}/${VM_NAME}.cfg; done
echo "]" >> ${OUTPUT_DIR}/${VM_NAME}.cfg

#boot image
xl create -c ${VM_NAME}.cfg
