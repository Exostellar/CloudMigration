import os
import sys

private_key = "/root/.ssh/id_rsa"

config = []
config_file = open("network.conf")
for line in config_file:
    vals = line.split()
    if len(vals) != 4 or vals[0][0] == '#':
        continue
        
    config.append(tuple(vals))
    
print "printing network config:"
for c in config:
    print c

for id, private_ip, public_ip, data_center in config:
    print "====Configuring: %s====" % (id)
    tunnel_config = ""
    for m_id, m_private_ip, m_public_ip, m_data_center in config:
        if m_data_center == data_center:
            tunnel_config += "%s %s\n" % (m_id, m_private_ip)
        else:
            tunnel_config += "%s %s\n" % (m_id, m_public_ip)
    os.system("source ./config.sh; ssh -i %s root@%s \"echo '%s' > /$BASE/tunnels.txt\"" % (private_key, public_ip, tunnel_config))
    os.system("source ./config.sh; ssh -i %s root@%s \"cd $BASE; python set_tunnels.py %s tunnels.txt\"" % (private_key, public_ip, private_ip))
