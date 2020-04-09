BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

TEMP="/root/workspace"   #recommend 10GB free in this directory

IPSUFFIX=14   #controller is fixed to 1
host_mtu=1500
guest_mtu=1360   #typically host_mtu-100

######1. required for setting up controller######
NFS_ROOT="/root/nfsroot"

######2. required for setting up xen-blanket######
HOSTNAME=vx1 #assign a hostname for host to be setup
platform=xen    #xen/kvm/hyperv
