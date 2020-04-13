BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

TEMP="/root/workspace"   #recommend 10GB free in this directory

IPSUFFIX=14   #VPN IP address: 192.168.1.$IPSUFFIX

guest_mtu=1360   #typically host_mtu-100

#Only used for Xen-Blanket setup:
dom0_cpu=4      #number of v-cpus for dom0
dom0_mem=4096   #memory size for dom0, in MB