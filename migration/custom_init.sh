#!/bin/bash

ovs-ofctl del-flows tunnel1.4
ovs-ofctl add-flow tunnel1.4 "table=0, priority=0, actions=drop"
ovs-ofctl add-flow tunnel1.4 "table=0, priority=99, in_port=1, actions=set_field:20->tun_id,NORMAL"
ovs-ofctl add-flow tunnel1.4 "table=0, priority=80, tun_id=21, actions=drop"
ovs-ofctl add-flow tunnel1.4 "table=0, priority=50, tun_id=20, actions=set_field:21->tun_id,NORMAL"
