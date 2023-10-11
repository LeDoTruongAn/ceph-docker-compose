#!/bin/bash

# Set Ceph configuration parameters in ceph.conf
set -x
echo "max open files = 655350" | sudo tee -a ceph_conf/ceph.conf
echo "cephx cluster require signatures = false" | sudo tee -a ceph_conf/ceph.conf
echo "cephx service require signatures = false" | sudo tee -a ceph_conf/ceph.conf
echo "mon_osd_allow_reclaim = false" | sudo tee -a ceph_conf/ceph.conf
echo "mon_max_pg_per_osd = 800" | sudo tee -a ceph_conf/ceph.conf

# Adjust OSD pool settings
# For one copy, size 1, these settings must be for OSD
echo "osd_pool_default_size = 3" | sudo tee -a ceph_conf/ceph.conf
echo "osd_pool_default_min_size = 2" | sudo tee -a ceph_conf/ceph.conf
echo "osd_pool_default_pg_num = 333" | sudo tee -a ceph_conf/ceph.conf
echo "osd_crush_chooseleaf_type = 1" | sudo tee -a ceph_conf/ceph.conf

# Additional OSD settings
echo "[osd]" | sudo tee -a ceph_conf/ceph.conf
echo "osd_journal_size = 5120" | sudo tee -a ceph_conf/ceph.conf
echo "osd_memory_target = 512MB" | sudo tee -a ceph_conf/ceph.conf

set +x
# Create an administrator password file (use a more secure method)
echo "administrator_password" > ceph_conf/ceph_password.txt
# Get the operating system type
OS=$(uname -s)

# Define the Docker Compose command based on the OS
if [ "$OS" = "Darwin" ]; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif [ "$OS" = "Linux" ]; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi
# Restart Ceph components to apply changes without health warnings
$DOCKER_COMPOSE_CMD restart ceph-mon ceph-mgr
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool create default.rgw.buckets.data 512 512
$DOCKER_COMPOSE_CMD exec ceph-mon ceph osd pool application enable default.rgw.buckets.data rgw
