BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

TEMP="/root/workspace"   #recommend 10GB free in this directory

IPSUFFIX=14   #VPN IP address: 192.168.1.$IPSUFFIX
guest_mtu=1360   #typically host_mtu-100
