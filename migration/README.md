# Migration
Migration tool sets up Xen-blanket and the necessary network which would enable live VM migration between nodes across private and public clouds as well as across different public cloud providers.

## Preparation
The following preparations are needed for running the scripts.
1. The Xen-blanket in this project only supports CentOS7, hence it is necessary that you have CentOS7 environment for the first layer VM.
2. SELinux must be disabled;
3. Make sure to open udp port 655, it is needed for setting up vpn tunnels.

## Getting started
### Setup a controller
1. Download the code to the controller, specify your configuration for the controller in config.sh. Make sure that IPSUFFIX=1.
2. Then run setup_controller.sh.

### Setup xen-blanket and basic network on other nodes:
1. Download the code to the VM, specify your configuration for each xen-blanket node in config.sh. 
2. Make sure that you are using unique IPSUFFIX for each node, and guest_mtu must be the same across the whole cluster. Otherwise they will have trouble communicating with each other.
3. "platform" in config.sh specifies what driver we are going to install. Usually "xen" is for AWS and "kvm" for Google.
4. Once xen-blanket works, run setup_xenblanket_2.sh.

### Connect all nodes into the basic network:
    
1. Propagate the controller's public key to all nodes(including itself), so that it can login to every node with the root account. Some nodes might disable root access. You should enable it if you want to use the following scripts.
2. On controller, modify network.conf. Follow the comment and examples there.
3. Then on controller, run "python build_network.py". It will login to each node and setup the tunnels. 
    
### Add customized init script
If you want the network setup to work on boot in the future, you could add sample.service to /etc/systemd/system.

### Configurate IP for Dom U
You need to configurate static IP for guest vms on xen-blanket. Here is a sample for CentOS.

```
#/etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPADDR=192.168.10.111
NETMASK=255.255.255.0
GATEWAY=192.168.1.11
NAME=eth0
DEVICE=eth0
MTU=8901
ONBOOT=yes
DNS1=8.8.8.8
DNS2=8.8.4.4 
```
