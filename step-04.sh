#!/bin/bash
source load-env.sh

# Enable Ceph Dashboard
# List of container names
containers=("ceph-mon" "ceph-mgr" "ceph-osd1" "ceph-osd2" "ceph-osd3" "ceph-rgw" "ceph-mds" "ceph-rbd")

for container in "${containers[@]}"; do
    $DOCKER_COMPOSE_CMD exec "${container}" /usr/sbin/sshd
done

# Define the hostnames and IP addresses
hosts=("ceph-mon" "ceph-mgr" "ceph-osd1" "ceph-osd2" "ceph-osd3" "ceph-rgw" "ceph-mds" "ceph-rbd")
ip_addresses=("192.168.55.2" "192.168.55.3" "192.168.55.4" "192.168.55.5" "192.168.55.6" "192.168.55.7" "192.168.55.8" "192.168.55.9")

# Iterate through the arrays to add hosts
for ((i=0; i<${#hosts[@]}; i++)); do
    $DOCKER_COMPOSE_CMD exec ceph-mon ceph orch host add "${hosts[i]}" "${ip_addresses[i]}"
done
