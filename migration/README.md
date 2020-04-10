# Migration
Migration tool sets up Xen-blanket and the necessary network which would enable live VM migration between nodes across private and public clouds as well as across different public cloud providers.

## Requirements
The following preparations are needed for running the scripts.
* The setup scripts in this folder are only tested on CentOS-7, hence it is necessary that you first-layer VMs use CentOS-7;
* SELinux must be disabled;
* Make sure to open UDP port 655 for your VMs. It is needed for setting up VPN tunnels. On Amazon EC2, you need to configure security groups. On Google Compute Engine, you need to change the firewall rules for the network interface.
* For the scripts of setting up VXLAN tunnels to work, you should download this repository to the same location across all your first-layer VMs.
* The VPN created by these scripts uses static IP within `192.168.1.0/24`. Make sure that it does not conflict with your existing setup.

## Getting started
The following steps are assuming that you are running the commands as the `root` user.

### 1. Update `config.sh`:
1. `TEMP`: The folder for putting temporal files.
2. `IPSUFFIX`: Each first-layer VM should get an unique `IPSUFFIX`, which implies an unique VPN IP address.
3. `guest_mtu`: MTU to use for the VPN.

### 2. Setup Xen-Blanket:
Run `setup_xenblanket.sh`. If successful, it will print out "All completed. Check grub before reboot!". Reboot the VM after verifying that the Grub has been updated to boot with the Xen hypervisor.

### 3. Setup Open-vSwitch:
Run `setup_ovs.sh`. If successful, it will print out "ALL FINISHED."

### 4. Setup VXLAN tunnels:
After you have finished the previous steps on all the VMs you want to connect with a VPN, choose one of them as the controller to run the following scripts. You only need to run this script once on the controller.

1. Propagate the controller's public key to all nodes(including itself), so that it can login to every node using the root account without a password. Some VMs might disable root access. You should enable it if you want to use the following scripts.
2. On controller, modify network.conf. Follow the comment and examples there.
3. On controller, run "python build_network.py". It will login to each node and setup the tunnels.

### 5. Bridging to the physical network:
If you want to bridge the VPN to the physical network, you can just attach the physical NIC to the `xenbr0` bridge created by the script:

```
ovs-vsctl add-port xenbr0 eth0
```

### 6. Configurate IP for Dom U
You need to configurate static IP for guest VMs on Xen-Blanket, and use the DOM-0 IP as the gateway. Here is a sample for CentOS.

```
#/etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPADDR=192.168.1.111
NETMASK=255.255.255.0
GATEWAY=192.168.1.11
NAME=eth0
DEVICE=eth0
MTU=8901
ONBOOT=yes
DNS1=8.8.8.8
DNS2=8.8.4.4
```
