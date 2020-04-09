import os
import sys

bridge_prefix = "brvif"
bridges = ["1.4"]
tunnel_prefix = "tunnel"
port_numbers = [655]

for index, bridge in enumerate(bridges):
    bridge_name = bridge_prefix + bridge
    tunnel_name = tunnel_prefix + bridge
    port_number = port_numbers[index]
    
    #os.system("iptables -I INPUT -m state --state NEW -p udp --dport %s -s 0.0.0.0/0 -j ACCEPT" % (port_number))

    
    os.system("ovs-vsctl add-br %s -- set Bridge %s fail-mode=secure" % (tunnel_name, tunnel_name))
    
    os.system("ovs-vsctl add-port %s patch_%s -- set Interface patch_%s type=patch options:peer=patch_%s" % (bridge_name, bridge_name, bridge_name, tunnel_name))
    os.system("ovs-vsctl add-port %s patch_%s -- set Interface patch_%s type=patch options:peer=patch_%s" % (tunnel_name, tunnel_name, tunnel_name, bridge_name))
    os.system("ovs-vsctl set interface patch_%s ofport_request=1" % (tunnel_name))
    
    cmd = "ovs-ofctl del-flows %s" % (tunnel_name)
    os.system(cmd)
    os.system("echo \'%s\' > /etc/custom_init.sh" % (cmd))   
 
    cmd = "ovs-ofctl add-flow %s \"table=0, priority=0, actions=drop\"" % (tunnel_name)
    os.system(cmd)
    os.system("echo \'%s\' >> /etc/custom_init.sh" % (cmd))
 
    cmd = "ovs-ofctl add-flow %s \"table=0, priority=99, in_port=1, actions=set_field:20->tun_id,NORMAL\"" % (tunnel_name)
    os.system(cmd)
    os.system("echo \'%s\' >> /etc/custom_init.sh" % (cmd))
 
    cmd = "ovs-ofctl add-flow %s \"table=0, priority=80, tun_id=21, actions=drop\"" % (tunnel_name)
    os.system(cmd)
    os.system("echo \'%s\' >> /etc/custom_init.sh" % (cmd))
 
    cmd = "ovs-ofctl add-flow %s \"table=0, priority=50, tun_id=20, actions=set_field:21->tun_id,NORMAL\"" % (tunnel_name)
    os.system(cmd)
    os.system("echo \'%s\' >> /etc/custom_init.sh" % (cmd))    
 
#os.system("service iptables save")

print "all finished"
